require "rails"

%w(
  active_record
  action_controller
  action_mailer
  active_resource
  rails/test_unit
  sprockets/rails
).each do |framework|
  begin
    require "#{framework}/railtie"
  rescue LoadError
  end
end
