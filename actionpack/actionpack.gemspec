require File.join(File.dirname(__FILE__), 'lib', 'action_pack', 'version')

PKG_BUILD = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME = 'actionpack'
PKG_VERSION = ActionPack::VERSION::STRING + PKG_BUILD
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

dist_dirs = [ "lib", "test" ]


# Create compressed packages
spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = PKG_NAME
  s.summary = "Service layer for easy email delivery and testing."
  s.description = %q{Makes it trivial to test and deliver emails sent from a single service layer.}
  s.version = PKG_VERSION

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.rubyforge_project = "actionmailer"
  s.homepage = "http://www.rubyonrails.org"

  s.add_dependency('actionpack', '= 2.3.2' + PKG_BUILD)

  s.has_rdoc = true
  s.requirements << 'none'
  s.require_path = 'lib'
  s.autorequire = 'action_mailer'

  s.files = [ "Rakefile", "install.rb", "README", "CHANGELOG", "MIT-LICENSE" ]
  s.files = s.files + Dir.glob( "lib/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  s.files = s.files + Dir.glob( "test/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
end

