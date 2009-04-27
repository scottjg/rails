
module ActionView #:nodoc:
  class SafeBuffer < String
    def <<(value)
      if value.html_safe?
        super(value)
      else
        super(CGI.escapeHTML(value))
      end
    end

    def html_safe?
      true
    end

    def html_safe!
      self
    end
  end
end