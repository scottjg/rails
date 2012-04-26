require 'date'
require 'active_support/core_ext/time/calculations'

class String
  # Form can be either :utc (default) or :local.
  def to_time(form = :utc)
    return nil if blank?

    keys = [:year, :mon, :mday, :hour, :min, :sec, :sec_fraction, :offset]
    date_values = ::Date._parse(self, false).values_at(*keys)
    date_values.map! { |arg| arg || 0 }
    date_values[6] *= 1000000
    offset = date_values.pop

    ::Time.send("#{form}_time", *date_values) - offset
  end

  def to_date
    return nil if blank?

    keys = [:year, :mon, :mday]
    date_values = ::Date._parse(self, false).values_at(*keys)

    ::Date.new(*date_values)
  end

  def to_datetime
    return nil if blank?

    keys = [:year, :mon, :mday, :hour, :min, :sec, :zone, :sec_fraction]
    date_values = ::Date._parse(self, false).values_at(*keys)
    date_values.map! { |arg| arg || 0 }
    date_values[5] += date_values.pop

    ::DateTime.civil(*date_values)
  end
end
