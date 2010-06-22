# Aliases Net::HTTPResponse#body is aliased to automatically inflate the body.
Net::HTTPResponse.class_eval do
  def body_with_inflate
    return @body if @read
    body_without_inflate
    @body = Zlib::Inflate.inflate(@body) if self["content-encoding"] == "deflate"
    @body
  end
  alias_method_chain :body, :inflate
end
