require File.join(File.dirname(__FILE__), 'lib', 'action_pack', 'version')

pkg_build     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
pkg_name      = 'actionpack'
pkg_versiON   = ActionPack::VERSION::STRING + pkg_build
pkg_file_NAME = "#{pkg_name}-#{pkg_version}"

dist_dirs = [ "lib", "test" ]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = pkg_name
  s.version = pkg_version
  s.summary = "Web-flow and rendering framework putting the VC in MVC."
  s.description = %q{Eases web-request routing, handling, and response as a half-way front, half-way page controller. Implemented with specific emphasis on enabling easy unit/integration testing that doesn't require a browser.} #'

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.rubyforge_project = "actionpack"
  s.homepage = "http://www.rubyonrails.org"

  s.has_rdoc = true
  s.requirements << 'none'

  s.add_dependency('activesupport', '= 2.3.10' + pkg_build)
  s.add_dependency('rack', '~> 1.1.0')

  s.require_path = 'lib'
  s.autorequire = 'action_controller'

  s.files = [ "Rakefile", "install.rb", "README", "RUNNING_UNIT_TESTS", "CHANGELOG", "MIT-LICENSE" ]
  dist_dirs.each do |dir|
    s.files = s.files + Dir.glob( "#{dir}/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  end
end
