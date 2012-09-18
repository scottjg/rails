require File.join(File.dirname(__FILE__), 'lib', 'active_support', 'version')

pkg_build     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
pkg_name      = 'activesupport'
pkg_version   = ActiveSupport::VERSION::STRING + pkg_build

dist_dirs = [ "lib", "test"]

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = pkg_name
  s.version = pkg_version
  s.summary = "Support and utility classes used by the Rails framework."
  s.description = %q{Utility library which carries commonly used classes and goodies from the Rails framework}

  s.files = [ "CHANGELOG", "README" ] + Dir.glob( "lib/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  s.require_path = 'lib'

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "activesupport"
end
