require 'abstract_unit'

class AuthorizationTest < Test::Unit::TestCase
  Response = Struct.new(:code)

  def setup
    @conn = ActiveResource::Connection.new('http://localhost')
    @matz  = { :id => 1, :name => 'Matz' }.to_xml(:root => 'person')
    @david = { :id => 2, :name => 'David' }.to_xml(:root => 'person')
    @authenticated_conn = ActiveResource::Connection.new("http://david:test123@localhost")
    @authorization_request_header = { 'Authorization' => 'Basic ZGF2aWQ6dGVzdDEyMw==' }

    ActiveResource::HttpMock.respond_to do |mock|
      mock.get    "/people/2.xml",           @authorization_request_header, @david
      mock.put    "/people/2.xml",           @authorization_request_header, nil, 204
      mock.delete "/people/2.xml",           @authorization_request_header, nil, 200
      mock.post   "/people/2/addresses.xml", @authorization_request_header, nil, 201, 'Location' => '/people/1/addresses/5'
    end
  end

  def test_authorization_header_not_added_when_explicitely_turn_off_basic_authentication
    @authenticated_conn.use_basic_authentication = false

    authorization_header = @authenticated_conn.__send__(:authorization_header)
    assert_equal Hash.new, authorization_header
  end

  def test_authorization_header_when_previous_www_authenticate_header_available_and_specifies_digest_authentication_accepted
    @authenticated_conn.use_digest_authentication = true
    @authenticated_conn.use_basic_authentication  = false

    # Because ActiveResource::Digest depends on Time.now, we reassign a known cnonce to allow canned values to be used
    silence_warnings do
      ActiveResource::Digest.const_set("CNONCE", ::Digest::MD5.hexdigest("%x" % 0))
    end

    authorization_header = @authenticated_conn.__send__(:authorization_header, "/people", :get, "WWW-Authenticate" => %(Digest realm="AdGear API", qop="auth", algorithm=MD5, nonce="MTI0OTQxMTQzNzplOTEwNzM1ZThiMmU3NzdiMGE4NmU2ODQ2MjI2ZjQzMA==", opaque="a21e6002d2bd70e6dbeaca094ded4f93"))

    assert_equal %(Digest username="david", realm="AdGear API", qop=auth, uri="/people", nonce="MTI0OTQxMTQzNzplOTEwNzM1ZThiMmU3NzdiMGE4NmU2ODQ2MjI2ZjQzMA==", nc=00000000, cnonce="cfcd208495d565ef66e7dff9f98764da", opaque="a21e6002d2bd70e6dbeaca094ded4f93", response="878fe453f5e15622a0d8f3b618ed8989"), authorization_header["Authorization"]
  end

  def test_authorization_header
    authorization_header = @authenticated_conn.__send__(:authorization_header)
    assert_equal @authorization_request_header['Authorization'], authorization_header['Authorization']
    authorization = authorization_header["Authorization"].to_s.split
    
    assert_equal "Basic", authorization[0]
    assert_equal ["david", "test123"], ActiveSupport::Base64.decode64(authorization[1]).split(":")[0..1]
  end
  
  def test_authorization_header_with_username_but_no_password
    @conn = ActiveResource::Connection.new("http://david:@localhost")
    authorization_header = @conn.__send__(:authorization_header)
    authorization = authorization_header["Authorization"].to_s.split
    
    assert_equal "Basic", authorization[0]
    assert_equal ["david"], ActiveSupport::Base64.decode64(authorization[1]).split(":")[0..1]
  end
  
  def test_authorization_header_with_password_but_no_username
    @conn = ActiveResource::Connection.new("http://:test123@localhost")
    authorization_header = @conn.__send__(:authorization_header)
    authorization = authorization_header["Authorization"].to_s.split
    
    assert_equal "Basic", authorization[0]
    assert_equal ["", "test123"], ActiveSupport::Base64.decode64(authorization[1]).split(":")[0..1]
  end
  
  def test_authorization_header_with_decoded_credentials_from_url
    @conn = ActiveResource::Connection.new("http://my%40email.com:%31%32%33@localhost")
    authorization_header = @conn.__send__(:authorization_header)
    authorization = authorization_header["Authorization"].to_s.split

    assert_equal "Basic", authorization[0]
    assert_equal ["my@email.com", "123"], ActiveSupport::Base64.decode64(authorization[1]).split(":")[0..1]
  end

  def test_authorization_header_explicitly_setting_username_and_password
    @authenticated_conn = ActiveResource::Connection.new("http://@localhost")
    @authenticated_conn.user = 'david'
    @authenticated_conn.password = 'test123'
    authorization_header = @authenticated_conn.__send__(:authorization_header)
    assert_equal @authorization_request_header['Authorization'], authorization_header['Authorization']
    authorization = authorization_header["Authorization"].to_s.split

    assert_equal "Basic", authorization[0]
    assert_equal ["david", "test123"], ActiveSupport::Base64.decode64(authorization[1]).split(":")[0..1]
  end

  def test_authorization_header_explicitly_setting_username_but_no_password
    @conn = ActiveResource::Connection.new("http://@localhost")
    @conn.user = "david"
    authorization_header = @conn.__send__(:authorization_header)
    authorization = authorization_header["Authorization"].to_s.split

    assert_equal "Basic", authorization[0]
    assert_equal ["david"], ActiveSupport::Base64.decode64(authorization[1]).split(":")[0..1]
  end

  def test_authorization_header_explicitly_setting_password_but_no_username
    @conn = ActiveResource::Connection.new("http://@localhost")
    @conn.password = "test123"
    authorization_header = @conn.__send__(:authorization_header)
    authorization = authorization_header["Authorization"].to_s.split

    assert_equal "Basic", authorization[0]
    assert_equal ["", "test123"], ActiveSupport::Base64.decode64(authorization[1]).split(":")[0..1]
  end

  def test_get
    david = @authenticated_conn.get("/people/2.xml")
    assert_equal "David", david["name"]
  end
  
  def test_post
    response = @authenticated_conn.post("/people/2/addresses.xml")
    assert_equal "/people/1/addresses/5", response["Location"]
  end
  
  def test_put
    response = @authenticated_conn.put("/people/2.xml")
    assert_equal 204, response.code
  end
  
  def test_delete
    response = @authenticated_conn.delete("/people/2.xml")
    assert_equal 200, response.code
  end

  def test_raises_invalid_request_on_unauthorized_requests
    assert_raise(ActiveResource::InvalidRequestError) { @conn.post("/people/2.xml") }
    assert_raise(ActiveResource::InvalidRequestError) { @conn.post("/people/2/addresses.xml") }
    assert_raise(ActiveResource::InvalidRequestError) { @conn.put("/people/2.xml") }
    assert_raise(ActiveResource::InvalidRequestError) { @conn.delete("/people/2.xml") }
  end

  protected
    def assert_response_raises(klass, code)
      assert_raise(klass, "Expected response code #{code} to raise #{klass}") do
        @conn.__send__(:handle_response, Response.new(code))
      end
    end
end
