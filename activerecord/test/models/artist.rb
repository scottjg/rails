class Artist < ActiveRecord::Base
  # Defines a non existing attribute decorating multiple existing attributes
  attribute_decorator :date_of_birth, :class_name => 'Decorators::CompositeDate', :decorates => [:day, :month, :year]
  
  # Defines a decorates for one attribute.
  attribute_decorator :gps_location, :class_name => 'Decorators::GPSCoordinator', :decorates => :location
  
  # Defines a decorator for an existing attribute.
  attribute_decorator :start_year, :class_name => 'Decorators::Year'
  
  # These validations are defined inline in the test cases. See attribute_decorator_test.rb.
  #
  # validates_decorator :date_of_birth, :start_year
  # validates_decorator :start_year, :message => 'is not a valid date', :on => :update
end

module Decorators
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