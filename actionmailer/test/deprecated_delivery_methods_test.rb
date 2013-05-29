require 'abstract_unit'
require 'mail'

class MyCustomDelivery
end

module DeprecatedDeliveryMethodsTest
  class DefaultsDeliveryMethodsTest < ActiveSupport::TestCase
    test "default smtp settings" do
      settings = { address:              "localhost",
                   port:                 25,
                   domain:               'localhost.localdomain',
                   user_name:            nil,
                   password:             nil,
                   authentication:       nil,
                   enable_starttls_auto: true }
      assert_equal settings, ActionMailer::Base.smtp_settings
    end

    test "default file delivery settings" do
      settings = {location: "#{Dir.tmpdir}/mails"}
      assert_equal settings, ActionMailer::Base.file_settings
    end

    test "default sendmail settings" do
      settings = {location:  '/usr/sbin/sendmail',
                  arguments: '-i -t'}
      assert_equal settings, ActionMailer::Base.sendmail_settings
    end
  end

  class CustomDeliveryMethodsTest < ActiveSupport::TestCase
    def setup
      @old_delivery_method = ActionMailer::Base.delivery_method
      ActionMailer::Base.add_delivery_method :custom, MyCustomDelivery
    end

    def teardown
      ActionMailer::Base.delivery_method = @old_delivery_method
      new = ActionMailer::Base.delivery_methods.dup
      new.delete(:custom)
      ActionMailer::Base.delivery_methods = new
    end

    test "allow to add custom delivery method" do
      ActionMailer::Base.delivery_method = :custom
      assert_equal :custom, ActionMailer::Base.delivery_method
    end

    test "allow to customize custom settings" do
      ActionMailer::Base.custom_settings = { foo: :bar }
      assert_equal Hash[foo: :bar], ActionMailer::Base.custom_settings
    end

    test "respond to custom settings" do
      assert_respond_to ActionMailer::Base, :custom_settings
      assert_respond_to ActionMailer::Base, :custom_settings=
    end

    test "does not respond to unknown settings" do
      assert_raise NoMethodError do
        ActionMailer::Base.another_settings
      end
    end
  end

end
