require File.join(File.dirname(__FILE__), 'lib', 'active_resource', 'version')

pkg_build     = ENV['pkg_build'] ? '.' + ENV['PKG_BUILD'] : ''
pkg_name      = 'activeresource'
pkg_version   = ActiveResource::VERSION::STRING + pkg_build

dist_dirs = [ "lib", "test", "examples", "dev-utils" ]

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = pkg_name
  s.version = pkg_version
  s.summary = "Think Active Record for web resources."
  s.description = %q{Wraps web resources in model classes that can be manipulated through XML over REST.}

  s.files = [ "Rakefile", "README", "CHANGELOG" ]

  dist_dirs.each do |dir|
    s.files = s.files + Dir.glob( "#{dir}/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  end
  
  s.add_dependency('activesupport', '= 2.3.14' + pkg_build)

  s.require_path = 'lib'

  s.extra_rdoc_files = %w( README )
  s.rdoc_options.concat ['--main',  'README']
  
  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "activeresource"
end
