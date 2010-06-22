class HTTPResponseTests < Test::Unit::TestCase
  def test_inflate_method_with_deflated_data
    response = Net::HTTPOK.new('1.1','200','OK')
    response.add_field "content-encoding", "deflate"
    test_string = '<chunky>bacon!</chunky>'
    io = StringIO.new(Zlib::Deflate.deflate(test_string))

    response.reading_body(Net::BufferedIO.new(io), true) { yield response if block_given? }

    assert_equal test_string, response.body
  end

  def test_inflate_method_with_standard_data
    response = Net::HTTPOK.new('1.1','200','OK')
    test_string = '<chunky>bacon!</chunky>'
    io = StringIO.new(test_string)

    response.reading_body(Net::BufferedIO.new(io), true) { yield response if block_given? }

    assert_equal test_string, response.body
  end
end
