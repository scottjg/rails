require File.join(File.dirname(__FILE__), 'lib', 'active_resource', 'version')

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'activeresource'
  s.version = ActiveResource::VERSION::STRING
  s.summary = "Think Active Record for web resources."
  s.description = %q{Wraps web resources in model classes that can be manipulated through XML over REST.}

  s.files = [ "Rakefile", "README", "CHANGELOG" ]
  [ "lib", "test", "examples", "dev-utils" ].each do |dir|
    s.files = s.files + Dir.glob( "#{dir}/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  end

  s.add_dependency('activesupport', '= 2.3.14')

  s.require_path = 'lib'

  s.extra_rdoc_files = %w( README )
  s.rdoc_options.concat ['--main',  'README']

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "activeresource"
end
