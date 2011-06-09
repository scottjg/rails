require File.join(File.dirname(__FILE__), 'lib', 'active_support', 'version')

spec = Gem::Specification.new do |s|
  pkg_build     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
  pkg_name      = 'activesupport'
  pkg_version   = ActiveSupport::VERSION::STRING + pkg_build
  pkg_file_name = "#{pkg_name}-#{pkg_version}"

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