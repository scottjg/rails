require 'bundler/setup'
require 'composed_of'
require 'minitest/spec'
require 'minitest/autorun'
require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.configurations = {:foo => "bar"}

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :posts do |t|
    t.string :title
  end
end

class Post < ActiveRecord::Base
  attr_accessible :id, :title
end

require 'active_support/testing/deprecation'
ActiveSupport::Deprecation.debug = true

class MiniTest::Spec
  include ActiveSupport::Testing::Deprecation
end

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  self.fixture_path = File.expand_path("../fixtures", __FILE__)
  self.use_instantiated_fixtures  = false
  self.use_transactional_fixtures = true

  def create_fixtures(*table_names, &block)
    ActiveRecord::Fixtures.create_fixtures(ActiveSupport::TestCase.fixture_path, table_names, fixture_class_names, &block)
  end
end

def load_schema
  # silence verbose schema loading
  original_stdout = $stdout
  $stdout = StringIO.new

  require_relative "schema.rb"
ensure
  $stdout = original_stdout
end

load_schema


