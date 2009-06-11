require 'digest/md5'
require 'active_support/core_ext/module/delegation'

module ActionDispatch # :nodoc:
  # Represents an HTTP response generated by a controller action. One can use
  # an ActionController::Response object to retrieve the current state
  # of the response, or customize the response. An Response object can
  # either represent a "real" HTTP response (i.e. one that is meant to be sent
  # back to the web browser) or a test response (i.e. one that is generated
  # from integration tests). See CgiResponse and TestResponse, respectively.
  #
  # Response is mostly a Ruby on Rails framework implement detail, and
  # should never be used directly in controllers. Controllers should use the
  # methods defined in ActionController::Base instead. For example, if you want
  # to set the HTTP response's content MIME type, then use
  # ActionControllerBase#headers instead of Response#headers.
  #
  # Nevertheless, integration tests may want to inspect controller responses in
  # more detail, and that's when Response can be useful for application
  # developers. Integration test methods such as
  # ActionController::Integration::Session#get and
  # ActionController::Integration::Session#post return objects of type
  # TestResponse (which are of course also of type Response).
  #
  # For example, the following demo integration "test" prints the body of the
  # controller response to the console:
  #
  #  class DemoControllerTest < ActionController::IntegrationTest
  #    def test_print_root_path_to_console
  #      get('/')
  #      puts @response.body
  #    end
  #  end
  class Response < Rack::Response
    DEFAULT_HEADERS = { "Cache-Control" => "no-cache" }
    attr_accessor :request

    attr_writer :header
    alias_method :headers=, :header=

    delegate :default_charset, :to => 'ActionController::Base'

    def initialize
      super
      @header = Rack::Utils::HeaderHash.new(DEFAULT_HEADERS)
    end

    # The response code of the request
    def response_code
      status.to_s[0,3].to_i rescue 0
    end

    # Returns a String to ensure compatibility with Net::HTTPResponse
    def code
      status.to_s.split(' ')[0]
    end

    def message
      status.to_s.split(' ',2)[1] || StatusCodes::STATUS_CODES[response_code]
    end
    alias_method :status_message, :message

    def body
      str = ''
      each { |part| str << part.to_s }
      str
    end

    def body=(body)
      @body = body.respond_to?(:to_str) ? [body] : body
    end

    def body_parts
      @body
    end

    def location
      headers['Location']
    end
    alias_method :redirect_url, :location

    def location=(url)
      headers['Location'] = url
    end

    # Sets the HTTP response's content MIME type. For example, in the controller
    # you could write this:
    #
    #  response.content_type = "text/plain"
    #
    # If a character set has been defined for this response (see charset=) then
    # the character set information will also be included in the content type
    # information.
    attr_writer :charset
    # def content_type=(mime_type)
    #   type = mime_type.to_s
    #   if type !~ /charset/ && (c = charset)
    #     type << "; charset=#{c}"
    #   end
    #   headers["Content-Type"] = type
    # end

    def content_type=(type)
      @content_type = type
    end

    # Returns the response's content MIME type, or nil if content type has been set.
    def content_type
      @content_type
      # content_type = @content_type.split(";")[0]
      # content_type = nil if content_type.blank?
      # content_type && Mime::Type.lookup(content_type)
    end

    # Set the charset of the Content-Type header. Set to nil to remove it.
    # If no content type is set, it defaults to HTML.
    # def charset=(charset)
    #   header_type = (content_type || Mime::HTML).to_s.dup
    #   header_type << "; charset=#{charset}" if charset
    #   headers["Content-Type"] = header_type
    # end

    def charset
      @charset
      # charset = String(headers["Content-Type"] || headers["type"]).split(";")[1]
      # charset.blank? ? nil : charset.strip.split("=")[1]
    end

    def last_modified
      if last = headers['Last-Modified']
        Time.httpdate(last)
      end
    end

    def last_modified?
      headers.include?('Last-Modified')
    end

    def last_modified=(utc_time)
      headers['Last-Modified'] = utc_time.httpdate
    end

    def etag
      headers['ETag']
    end

    def etag?
      headers.include?('ETag')
    end

    def etag=(etag)
      if etag.blank?
        headers.delete('ETag')
      else
        headers['ETag'] = %("#{Digest::MD5.hexdigest(ActiveSupport::Cache.expand_cache_key(etag))}")
      end
    end

    def sending_file?
      headers["Content-Transfer-Encoding"] == "binary"
    end

    def assign_default_content_type_and_charset!
      return if !headers["Content-Type"].blank?
      
      @content_type ||= Mime::HTML
      @charset      ||= default_charset
      
      type = @content_type.to_s
      type << "; charset=#{@charset}" unless sending_file?
      
      headers["Content-Type"] = type
      # 
      # if type = headers['Content-Type']
      #   unless type =~ /charset=/ || sending_file?
      #     headers['Content-Type'] = "#{type}; charset=#{default_charset}"
      #   end
      # else
      #   type = Mime::HTML.to_s
      #   type += "; charset=#{default_charset}" unless sending_file?
      #   headers['Content-Type'] = type
      # end
    end

    def prepare!
      assign_default_content_type_and_charset!
      handle_conditional_get!
      set_content_length!
      convert_content_type!
      convert_language!
      convert_cookies!
    end

    def each(&callback)
      if @body.respond_to?(:call)
        @writer = lambda { |x| callback.call(x) }
        @body.call(self, self)
      else
        @body.each { |part| callback.call(part.to_s) }
      end

      @writer = callback
      @block.call(self) if @block
    end

    def write(str)
      str = str.to_s
      @writer.call str
      str
    end

    def set_cookie(key, value)
      if value.has_key?(:http_only)
        ActiveSupport::Deprecation.warn(
          "The :http_only option in ActionController::Response#set_cookie " +
          "has been renamed. Please use :httponly instead.", caller)
        value[:httponly] ||= value.delete(:http_only)
      end

      super(key, value)
    end

    # Returns the response cookies, converted to a Hash of (name => value) pairs
    #
    #   assert_equal 'AuthorOfNewPage', r.cookies['author']
    def cookies
      cookies = {}
      if header = headers['Set-Cookie']
        header = header.split("\n") if header.respond_to?(:to_str)
        header.each do |cookie|
          if pair = cookie.split(';').first
            key, value = pair.split("=").map { |v| Rack::Utils.unescape(v) }
            cookies[key] = value
          end
        end
      end
      cookies
    end

    private
      def handle_conditional_get!
        if etag? || last_modified?
          set_conditional_cache_control!
        elsif nonempty_ok_response?
          self.etag = body

          if request && request.etag_matches?(etag)
            self.status = '304 Not Modified'
            self.body = []
          end

          set_conditional_cache_control!
        end
      end

      def nonempty_ok_response?
        ok = !status || status.to_s[0..2] == '200'
        ok && string_body?
      end

      def string_body?
        !body_parts.respond_to?(:call) && body_parts.any? && body_parts.all? { |part| part.is_a?(String) }
      end

      def set_conditional_cache_control!
        if headers['Cache-Control'] == DEFAULT_HEADERS['Cache-Control']
          headers['Cache-Control'] = 'private, max-age=0, must-revalidate'
        end
      end

      def convert_content_type!
        headers['Content-Type'] ||= "text/html"
        headers['Content-Type'] += "; charset=" + headers.delete('charset') if headers['charset']
      end

      # Don't set the Content-Length for block-based bodies as that would mean
      # reading it all into memory. Not nice for, say, a 2GB streaming file.
      def set_content_length!
        if status && status.to_s[0..2] == '204'
          headers.delete('Content-Length')
        elsif length = headers['Content-Length']
          headers['Content-Length'] = length.to_s
        elsif string_body? && (!status || status.to_s[0..2] != '304')
          headers["Content-Length"] = Rack::Utils.bytesize(body).to_s
        end
      end

      def convert_language!
        headers["Content-Language"] = headers.delete("language") if headers["language"]
      end

      def convert_cookies!
        headers['Set-Cookie'] =
          if header = headers['Set-Cookie']
            header = header.split("\n") if header.respond_to?(:to_str)
            header.compact
          else
            []
          end
      end
  end
end
