require File.join(File.dirname(__FILE__), 'lib', 'action_mailer', 'version')

unless defined? ACTIONMAILER_PKG_BUILD
ACTIONMAILER_PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
ACTIONMAILER_PKG_NAME      = 'actionmailer'
ACTIONMAILER_PKG_VERSION   = ActionMailer::VERSION::STRING + ACTIONMAILER_PKG_BUILD
ACTIONMAILER_PKG_FILE_NAME = "#{ACTIONMAILER_PKG_NAME}-#{ACTIONMAILER_PKG_VERSION}"
end

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = ACTIONMAILER_PKG_NAME
  s.summary = "Service layer for easy email delivery and testing."
  s.description = %q{Makes it trivial to test and deliver emails sent from a single service layer.}
  s.version = ACTIONMAILER_PKG_VERSION

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.rubyforge_project = "actionmailer"
  s.homepage = "http://www.rubyonrails.org"

  s.add_dependency('actionpack', '= 2.3.11' + ACTIONMAILER_PKG_BUILD)

  s.has_rdoc = true
  s.requirements << 'none'
  s.require_path = 'lib'
  s.autorequire = 'action_mailer'

  s.files = [ "Rakefile", "install.rb", "README", "CHANGELOG", "MIT-LICENSE" ]
  s.files = s.files + Dir.glob( "lib/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  s.files = s.files + Dir.glob( "test/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
end
