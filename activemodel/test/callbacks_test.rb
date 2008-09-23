require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class HasCallbacks < ActiveModel::Base
  
  attr_reader :logged_calls
  
  def save;  end
  def create_or_update
    
  end
  def before_save
    log_call(:before_save)
  end
  
  def log_call(call_name)
    @logged_calls ||= []
    @logged_calls << call_name
  end
end

class CallbacksTest < ActiveModel::TestCase
  def setup
    @model = HasCallbacks.new
  end

  test "Calls before save defined as method" do
    @model.save
    assert_equal [:before_save], @model.logged_calls
  end
end