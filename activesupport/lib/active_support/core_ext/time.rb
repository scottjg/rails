require 'date'
require 'time'

# Ruby 1.8-cvs and 1.9 define private Time#to_date
class Time
  %w(to_date to_datetime).each do |method|
    public method if private_instance_methods.include?(method)
  end
end

require 'active_support/core_ext/time/acts_like'
require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/time/marshal'
require 'active_support/core_ext/time/zones'
require 'active_support/core_ext/time/infinite_comparable'
