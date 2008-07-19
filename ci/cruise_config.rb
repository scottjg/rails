Project.configure do |project|
 project.build_command = 'ruby ../rails_build.rb'
 project.email_notifier.emails = ['rubyonrails-core@googlegroups.com']
 project.email_notifier.from = 'alexey.verkhovsky@gmail.com'
end