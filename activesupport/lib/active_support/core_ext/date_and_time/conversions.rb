module DateAndTime
  module Conversions

    # Convert to a formatted string.  See Time::DATE_FORMATS and Date::DATE_FORMATS
    # for predefined formats.
    #
    # This method is aliased to <tt>to_s</tt>.
    #
    #   date = Date.new(2007, 11, 10)       # => Sat, 10 Nov 2007
    #   date.to_formatted_s(:db)            # => "2007-11-10"
    #   date.to_s(:db)                      # => "2007-11-10"
    #
    #   time = Time.now                    # => Thu Jan 18 06:10:17 CST 2007
    #   time.to_formatted_s(:time)         # => "06:10"
    #   time.to_s(:time)                   # => "06:10"
    #
    #   datetime = DateTime.civil(2007, 12, 4, 0, 0, 0, 0)   # => Tue, 04 Dec 2007 00:00:00 +0000
    #   datetime.to_formatted_s(:db)            # => "2007-12-04 00:00:00"
    #   datetime.to_s(:db)                      # => "2007-12-04 00:00:00"
    #
    def to_formatted_s(format = :default)
      if formatter = self.class::DATE_FORMATS[format]
        if formatter.respond_to?(:call)
          formatter.call(self).to_s
        else
          strftime(formatter)
        end
      else
        to_default_s
      end
    end

    def self.included(base)
      base.class_eval do
        alias_method :to_default_s, :to_s if instance_methods(false).include?(:to_s)
        alias_method :to_s, :to_formatted_s
      end
    end
  end
end
