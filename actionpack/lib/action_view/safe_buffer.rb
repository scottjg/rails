
module ActionView #:nodoc:
  class SafeBuffer < String
    def <<(value)
      if value.html_safe?
        super(value)
      else
        super(CGI.escapeHTML(value))
      end
    end
  end
end