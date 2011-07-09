# http://37signals.com/svn/posts/2742-the-road-to-faster-tests
#
class ActiveSupport::TestCase
  teardown :scrub_instance_variables

  @@reserved_ivars = %w(@loaded_fixtures @test_passed @fixture_cache @method_name @_assertion_wrapped @_result)

  def scrub_instance_variables
    (instance_variables - @@reserved_ivars).each do |ivar|
      instance_variable_set(ivar, nil)
    end
  end
end
