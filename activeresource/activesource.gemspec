Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'activeresource'
  s.version = '2.3.8'
  s.summary = "Think Active Record for web resources."
  s.description = %q{Wraps web resources in model classes that can be manipulated through XML over REST.}

  s.files = Dir['CHANGELOG', 'README', 'lib/**/*']

  s.add_dependency('activesupport', '= 2.3.8')

  s.require_path = 'lib'
  s.autorequire = 'active_resource'

  s.has_rdoc = true
  s.extra_rdoc_files = %w( README )
  s.rdoc_options.concat ['--main', 'README']

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "activeresource"
end