require 'active_support/json'

module Cpanel
  class Response
    attr_accessor :response, :success

    def initialize(response)      
      response = ActiveSupport::JSON.decode(response)
      
      if response["result"]
        @response = response["result"][0] ? response["result"][0] : response["result"]
      else
        @response = response
      end
      
      @success = success?
    end
    
    def errors
      if success?
        nil
      else
        return response["statusmsg"] ? response["statusmsg"] : nil
      end
    end

    def success?
      return response["status"] ? response["status"] == 1 : true
    end
  end
end