class TimeChanger
  attr_accessor :time, :options

  def initialize(time, options)
    @time = time
    @options = options
  end

  def change
    if time.utc?
      as_utc
    elsif time.zone
      as_zone
    else
      as_standard
    end
  end

  private

    def as_utc
      ::Time.utc(new_year, new_month, new_day, new_hour, new_min, new_sec, new_usec)
    end

    def as_zone
      ::Time.local(new_year, new_month, new_day, new_hour, new_min, new_sec, new_usec)
    end

    def as_standard
      ::Time.new(new_year, new_month, new_day, new_hour, new_min, new_sec + (new_usec.to_r / 1000000), time.utc_offset)
    end

    def new_year
      options.fetch(:year, time.year)
    end

    def new_month
      options.fetch(:month, time.month)
    end

    def new_day
      options.fetch(:day, time.day)
    end

    def new_hour
      options.fetch(:hour, time.hour)
    end

    def new_min
      options.fetch(:min, options[:hour] ? 0 : time.min)
    end

    def new_sec
      options.fetch(:sec, (options[:hour] || options[:min]) ? 0 : time.sec)
    end

    def new_usec
      options.fetch(:usec, (options[:hour] || options[:min] || options[:sec]) ? 0 : Rational(time.nsec, 1000))
    end
end
