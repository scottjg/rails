require File.join(File.dirname(__FILE__), 'lib', 'active_support', 'version')

ACTIVESUPPORT_PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
ACTIVESUPPORT_PKG_NAME      = 'activesupport'
ACTIVESUPPORT_PKG_VERSION   = ActiveSupport::VERSION::STRING + ACTIVESUPPORT_PKG_BUILD
ACTIVESUPPORT_PKG_FILE_NAME = "#{ACTIVESUPPORT_PKG_NAME}-#{ACTIVESUPPORT_PKG_VERSION}"

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = ACTIVESUPPORT_PKG_NAME
  s.version = ACTIVESUPPORT_PKG_VERSION
  s.summary = "Support and utility classes used by the Rails framework."
  s.description = %q{Utility library which carries commonly used classes and goodies from the Rails framework}

  s.files = [ "CHANGELOG", "README" ] + Dir.glob( "lib/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  s.require_path = 'lib'
  s.has_rdoc = true

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "activesupport"
end