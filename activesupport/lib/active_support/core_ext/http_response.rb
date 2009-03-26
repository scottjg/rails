# Adds the 'inflate!' method to HTTPResponse.
module Net
  class HTTPResponse
    def inflate!
      @body = Zlib::Inflate.inflate(@body)
    end
  end
end
