module AttributeViews
  class CompositeDate
    attr_reader :day, :month, :year

    def self.parse(value)
      new *value.scan(/(\d\d)-(\d\d)-(\d{4})/).flatten.map { |x| x.to_i }
    end

    def initialize(day, month, year)
      @day, @month, @year = day, month, year
    end

    def valid?
      true
    end

    def to_a
      [@day, @month, @year]
    end

    def to_s
      "#{@day}-#{@month}-#{@year}"
    end
  end

  class GPSCoordinator
    attr_reader :location

    def self.parse(value)
      new(value == 'amsterdam' ? '+1, +1' : '-1, -1')
    end

    def initialize(location)
      @location = location
    end

    def to_a
      [@location]
    end

    def to_s
      @location
    end
  end

  class Year
    attr_reader :start_year

    def self.parse(value)
      new(value == '40 bc' ? -41 : value.to_i)
    end

    def initialize(start_year)
      @start_year = start_year
    end

    def valid?
      @start_year != 0
    end

    def to_a
      [@start_year]
    end
  end
end

class Artist < ActiveRecord::Base
  # Defines a non existing attribute decorating multiple existing attributes
  view :date_of_birth, :as => AttributeViews::CompositeDate, :decorating => [:day, :month, :year]

  # Defines a decorates for one attribute.
  view :gps_location, :as => AttributeViews::GPSCoordinator, :decorating => :location

  # Defines a decorator for an existing attribute.
  view :start_year, :as => AttributeViews::Year

  # These validations are defined inline in the test cases. See attribute_decorator_test.rb.
  #
  # validates_view :date_of_birth, :start_year
  # validates_view :start_year, :message => 'is not a valid date', :on => :update
end