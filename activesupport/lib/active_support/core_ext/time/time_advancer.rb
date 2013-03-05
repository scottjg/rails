class TimeAdvancer
  attr_accessor :time, :options

  def initialize(time, options)
    @time = time
    @options = options
  end

  def advance
    convert(:weeks, :days, 7)
    convert(:days, :hours, 24)

    if seconds_to_advance.zero?
      time_advanced_by_date
    else
      time_advanced_by_date.since(seconds_to_advance)
    end
  end

  private

    def time_advanced_by_date
      date = time.to_date.advance(options)
      time.change(:year => date.year, :month => date.month, :day => date.day)
    end

    def convert(parent, child, conversion)
      return unless options[parent].present?
      options[parent], partial = options[parent].divmod(1)
      options[child] = options.fetch(child, 0) + conversion * partial
    end

    def seconds_to_advance
      options.fetch(:seconds, 0) +
        options.fetch(:minutes, 0) * 60 +
        options.fetch(:hours, 0) * 3600
    end
end
