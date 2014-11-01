require 'test_helper'

class CpanelTest < Test::Unit::TestCase
  context "Server" do
    context "Setup" do
      should "default to username 'root'" do
        @server = Cpanel::Server.new(:url => "whm.example.com", :key => "example")
        assert_equal "root", @server.user
      end

      should "use the username supplied in the options hash" do
        @server = Cpanel::Server.new(:url => "whm.example.com", :key => "examplekey", :user => "whm_user")
        assert_equal "whm_user", @server.user
      end

      should "request authorisation using the specified user" do
        @server = Cpanel::Server.new(:url => "whm.example.com", :key => "examplekey", :user => "whm_user")

        net = mock
        net.expects(:add_field).at_least_once.with("Authorization", "WHM whm_user:examplekey")
        net.stubs(:set_form_data).returns(true)

        Net::HTTP::Get.expects(:new).returns(net)
        Cpanel::Response.expects(:new).returns(mock)
        
        mock_http = mock
        mock_http.stubs(:request).returns(true)

        @server.stubs(:http).returns(mock_http)
        @server.stubs(:handle_response).returns(true)

        # Trigger test
        @server.request("script")
      end
    end
  end
end
