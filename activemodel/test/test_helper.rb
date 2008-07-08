$LOAD_PATH << File.join(File.dirname(__FILE__), '..', '..', 'activesupport', 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'active_support'
require 'active_support/test_case'

require 'active_model'
require 'active_model/state_machine'
require 'active_model/validatable'

def uses_gem(gem_name, test_name, version = '> 0')
  require 'rubygems'
  gem gem_name.to_s, version
  require gem_name.to_s
  yield
rescue LoadError
  $stderr.puts "Skipping #{test_name} tests. `gem install #{gem_name}` and try again."
end

# Wrap tests that use Mocha and skip if unavailable.
unless defined? uses_mocha
  def uses_mocha(test_name, &block)
    uses_gem('mocha', test_name, '>= 0.5.5', &block)
  end
end

begin
  require 'rubygems'
  require 'ruby-debug'
  Debugger.start
rescue LoadError
end

ActiveSupport::TestCase.send :include, ActiveSupport::Testing::Default

module ActiveModel
  class TestCase < ActiveSupport::TestCase
    include ActiveSupport::Testing::Default
  end
end