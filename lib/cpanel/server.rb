require 'uri'
require 'net/https'
require 'openssl'
require 'active_resource'

module Cpanel
  class Server
    include ActiveResource
    
    attr_accessor :url, :key, :timeout, :api
    
    def initialize(options = {})
      @url = URI.parse(options[:url])
      @key = format_key(options[:key])
      @timeout = options[:timeout] || 300
      @api = options[:api] || "json"
    end
    
    def key=(api_key)
      @key = format_key(api_key)
    end
    
    def request(script, options = {})
      request = Net::HTTP::Get.new("/#{api}-api/" + script)
      request.add_field "Authorization", "WHM root:#{key}"
      request.set_form_data(options) unless options.empty?
      
      result = http.request(request)
      response = handle_response(result)
      
      return Response.new(response)
    rescue Timeout::Error, Errno::ETIMEDOUT => e
      raise TimeoutError.new(e.message)
    rescue Errno::ECONNREFUSED => e
      raise CommandFailed.new("Connection to cPanel server was refused; may be down or unreachable")
    end
    
    private
    
    def format_key(key)
      key.gsub("\n", "").gsub("\r", "").strip
    end
    
    def handle_response(response)
      case response.code.to_i
      when 301, 302 then raise(Redirection.new(response))
      when 200...400 then return(response.body)
      when 400 then raise(BadRequest.new(response))
      when 401 then raise(UnauthorizedAccess.new(response))
      when 403 then raise(ForbiddenAccess.new(response))
      when 404 then raise(ResourceNotFound.new(response))
      when 405 then raise(MethodNotAllowed.new(response))
      when 409 then raise(ResourceConflict.new(response))
      when 422 then raise(ResourceInvalid.new(response))
      when 401...500 then raise(ClientError.new(response))
      when 500...600 then raise(ServerError.new(response))
      else
        raise ConnectionError.new(response, "Unknown response code: #{response.code}")
      end
    end
    
    def http    
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if url.scheme == 'https'
      http.read_timeout = timeout
      http.open_timeout = timeout
      http
    end
  end
end