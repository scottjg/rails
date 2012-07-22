# Handles conversion of SQL time columns with values of "24:00" for roundtrips
# to the database.
#
#   time = Time.now.beginning_of_day    # => Sun Jul 22 00:00:00 PDT 2012
#   time.to_s(:db)                      # => "2012-07-22 00:00:00"
#
#   time.twenty_four                    # => Sun Jul 22 00:00:00 PDT 2012
#   time.to_s(:db)                      # => "2012-07-22 24:00:00"
#
#   time = Time.parse("24:00:00")       # => Sun Jul 22 00:00:00 PDT 2012
#   time.twenty_four?                   # => true
#   time.to_s(:db)                      # => "2012-07-22 24:00:00"
#
# Requiring this optional file overwrites the standard
# <tt>Time::DATE_FORMATS[:db]</tt> conversion to handle the '24:00' case.
class Time
  def twenty_four=(flag)
    @twenty_four = flag && self == beginning_of_day
    self
  end

  def twenty_four
    self.twenty_four = true
    self
  end

  def twenty_four?
    @twenty_four ||= false
  end

  class << self
    def new(*args)
      super(*args).tap do |t|
        t.twenty_four = [24 == args[3].to_i,
                          0 == args[4].to_i,
                          0 == args[5].to_i].all?
      end
    end

    def parse_with_twenty_four(string)
      parse_without_twenty_four(string).tap do |t|
        t.twenty_four = !!(/24:00(:00)?/ =~ string)
      end
    end
    alias_method :parse_without_twenty_four, :parse
    alias_method :parse, :parse_with_twenty_four
  end
end

Time::DATE_FORMATS[:db] = lambda { |t| t.twenty_four? ? (t - 1.day).strftime('%Y-%m-%d 24:00:00') : t.strftime('%Y-%m-%d %H:%M:%S') }
