require "cases/helper"
require "models/book"
require 'models/car'
require 'models/bulb'
require 'models/organization'
require 'models/category'
require 'models/categorization'

module ActiveRecord

  class StatementCacheTest < ActiveRecord::TestCase
    
    def setup
      @connection = ActiveRecord::Base.connection
    end

    class StatementCache
      def initialize
        @relation = yield
      end

      def execute(binds = nil)
        rel = @relation.dup    
        if (binds != nil)        
          rel.replace_binds binds
        end
        rel.to_a
      end
    end


    def test_create_from_association_with_nil_values_should_work #has_many_associations_test.rb: 142
      car = Car.create(:name => 'honda')

      bulb = car.bulbs.new(nil)
      assert_equal 'defaulty', bulb.name
    end

    #Fixed find_or_create_by by duping the attributes in relation.rb method of the same name
    def test_find_or_create_by
      Book.create(name: "my book")

      a = Book.find_or_create_by(name: "my book")
      b = Book.find_or_create_by(name: "my other book")

      assert_equal("my book", a.name)
      assert_equal("my other book", b.name)
    end

    #Fixed find_or_initialize_by by duping the attributes in relation.rb method of the same name
    def test_find_or_init_by
      Book.create(name: "my book")

      a = Book.find_or_initialize_by(name: "my book")    
      b = Book.find_or_initialize_by(name: "my other book")

      assert_equal("my book", a.name)
      assert_equal("my other book", b.name)
    end

    def test_statement_cache
      Book.create(name: "my book")
      Book.create(name: "my other book")

      cache = StatementCache.new do
        Book.where(:name => "my book")
      end

      b = cache.execute name: "my book"
      assert_equal "my book", b[0].name
      b = cache.execute name: "my other book"
      assert_equal "my other book", b[0].name
    end

  end
end