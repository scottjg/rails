Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'actionmailer'
  s.version = '2.3.16'
  s.summary = "Customised ActionMailer for REMS3." 
  s.description = 'Makes it trivial to test and deliver emails sent from a single service layer.'
  s.add_dependency('actionpack', '= 2.3.16')
  s.files = Dir['CHANGELOG', 'README', 'MIT-LICENSE', 'lib/**/*']
  s.has_rdoc = true
  s.requirements << 'none'
  s.require_path = 'lib'
  s.autorequire = 'action_mailer'
  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "actionmailer"
end
