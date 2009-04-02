class HTTPResponseTests < Test::Unit::TestCase
  def test_inflate_method
    response = Net::HTTPResponse.new
    test_string = '<chunky>bacon!</chunky>'
    
    response.instance_variable_set('@body', Zlib::Deflate.deflate(test_string))
    response.inflate!
    
    assert_equal test_string, response.instance_variable_get('@body')
  end
end
