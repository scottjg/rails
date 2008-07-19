Project.configure do |project|
 project.build_command = 'ruby ../rails_build.rb'
 project.email_notifier.emails = ['thewoolleyman@gmail.com']
 project.email_notifier.from = 'thewoolleyman+railsci@gmail.com'
end