require 'test/unit'

$:.unshift "#{File.dirname(__FILE__)}/../lib"
$:.unshift "#{File.dirname(__FILE__)}/../../activesupport/lib"
$:.unshift "#{File.dirname(__FILE__)}/../../actionpack/lib"
require 'active_orm'

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true

def uses_mocha(description)
  require 'rubygems'
  gem 'mocha', '>= 0.9.3'
  require 'mocha'
  yield
rescue LoadError
  $stderr.puts "Skipping #{description} tests. `gem install mocha` and try again."
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

class OrmModelProxy < ActiveOrm::Proxies::AbstractProxy
  def new?
    model.new_record?
  end
  
  def valid?
    model.valid?
  end
end

ActiveOrm::Core.register OrmModel, OrmModelProxy