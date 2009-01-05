require 'rubygems'
require 'test/unit'

$:.unshift "#{File.dirname(__FILE__)}/../lib"
$:.unshift "#{File.dirname(__FILE__)}/../../activesupport/lib"
$:.unshift "#{File.dirname(__FILE__)}/../../actionpack/lib"
require 'active_orm'
require 'active_orm/test_orm_model'
require 'active_orm/proxies/test_orm_proxy'

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

ActiveOrm.use :orm => :test_orm