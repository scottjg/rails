require 'active_record_unit'
# make sure that we can have fixtures that start with the word "test"
# when we use fixtures :all
class TestDataController < ActionController::Base
end

ActionController::TestCase.class_eval do
  self.fixture_path = [FIXTURE_LOAD_PATH]
  fixtures :all
end

class TestDataControllerTest < ActionController::TestCase
  def test_fixtures_loading
    assert(test_entries(:one).name == 'testdataname1')
  end
end

