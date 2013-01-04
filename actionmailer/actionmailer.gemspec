require File.join(File.dirname(__FILE__), 'lib', 'action_mailer', 'version')

pkg_build     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
pkg_name      = 'actionmailer'
pkg_version   = ActionMailer::VERSION::STRING + pkg_build
pKG_FILE_NAME = "#{pkg_name}-#{pkg_version}"

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = pkg_name
  s.summary = "Service layer for easy email delivery and testing."
  s.description = %q{Makes it trivial to test and deliver emails sent from a single service layer.}
  s.version = pkg_version

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.rubyforge_project = "actionmailer"
  s.homepage = "http://www.rubyonrails.org"

  s.add_dependency('actionpack', '= 2.3.14' + pkg_build)

  s.has_rdoc = true
  s.requirements << 'none'
  s.require_path = 'lib'
  s.autorequire = 'action_mailer'

  s.files = [ "Rakefile", "install.rb", "README", "CHANGELOG", "MIT-LICENSE" ]
  s.files = s.files + Dir.glob( "lib/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  s.files = s.files + Dir.glob( "test/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
end
