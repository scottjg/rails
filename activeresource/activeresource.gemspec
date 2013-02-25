require File.join(File.dirname(__FILE__), 'lib', 'active_resource', 'version')

ARES_PKG_BUILD = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
ARES_PKG_NAME = 'activeresource'
ARES_PKG_VERSION = ActiveResource::VERSION::STRING + ARES_PKG_BUILD
ARES_PKG_FILE_NAME = "#{ARES_PKG_NAME}-#{ARES_PKG_VERSION}"

dist_dirs = [ "lib", "test", "examples", "dev-utils" ]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = ARES_PKG_NAME
  s.version = ARES_PKG_VERSION
  s.summary = "Think Active Record for web resources."
  s.description = %q{Wraps web resources in model classes that can be manipulated through XML over REST.}

  s.files = [ "Rakefile", "README", "CHANGELOG" ]
  dist_dirs.each do |dir|
    s.files = s.files + Dir.glob( "#{dir}/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  end
  
  s.add_dependency('activesupport', '= 2.3.2' + ARES_PKG_BUILD)

  s.require_path = 'lib'
  s.autorequire = 'active_resource'

  s.has_rdoc = true
  s.extra_rdoc_files = %w( README )
  s.rdoc_options.concat ['--main',  'README']
  
  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "activeresource"
end
