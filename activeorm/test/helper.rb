require 'rubygems'
require 'test/unit'

$:.unshift "#{File.dirname(__FILE__)}/../lib"
$:.unshift "#{File.dirname(__FILE__)}/../../activesupport/lib"
$:.unshift "#{File.dirname(__FILE__)}/../../actionpack/lib"
require 'active_orm'

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true

def uses_mocha(description)
  gem 'mocha', '>= 0.9.3'
  require 'mocha'
  yield
rescue LoadError
  $stderr.puts "Skipping #{description} tests. `gem install mocha` and try again."
end

def uses_active_record(description)
    gem 'active_record'
    require 'active_record'
    yield
  rescue LoadError
    $stderr.puts "Skipping #{description} tests. `gem install active_record` and try again."
end

def uses_datamapper(description)
    gem 'dm-core'
    gem 'dm-validations'
    require 'dm-core'
    require 'dm-validations'
    yield
  rescue LoadError
    $stderr.puts "Skipping #{description} tests. `gem install dm-core dm-validations` and try again."
end

module OrmModule
end

class OrmModel
  
  def initialize
    @new = true
    @valid = true
  end
  def save
    @new = false
  end
  def new_record?
    @new
  end
  def invalidate
    @valid = false
  end
  def valid?
    @valid
  end
end

class OrmModuleModel
  include OrmModule
  
  def initialize
    @new = true
    @valid = true
  end
  def save
    @new = false
  end
  def new_record?
    @new
  end
  def invalidate
    @valid = false
  end
  def valid?
    @valid
  end
end

class OrmModelProxy < ActiveOrm::Proxies::AbstractProxy
  def new?
    model.new_record?
  end
  
  def valid?
    model.valid?
  end
end

ActiveOrm::Core.register OrmModel, OrmModelProxy
ActiveOrm::Core.register OrmModule, OrmModelProxy