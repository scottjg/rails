class Object
  # Alias of <tt>to_s</tt>.
  def to_param
    to_s
  end

  # Converts an object into a string suitable for use as a URL query string, using the given <tt>key</tt> as the
  # param name.
  #
  # Note: This method is defined as a default implementation for all Objects for Hash#to_query to work.
  def to_query(key)
    require 'cgi' unless defined?(CGI) && defined?(CGI::escape)
    begin
      "#{CGI.escape(key.to_s)}=#{CGI.escape(to_param.to_s)}"
    rescue
      require 'active_support/inflector' unless defined?(ActiveSupport::Inflector)
      "#{CGI.escape(key.to_s)}=#{CGI.escape(ActiveSupport::Inflector.transliterate(to_param.to_s))}"
    end
  end
end
