Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'actionpack'
  s.version = '2.3.16'
  s.summary = "Customised ActionPack for REMS3." 
  s.description = 'Eases web-request routing, handling, and response as a half-way front, half-way page controller. Implemented with specific emphasis on enabling easy unit/integration testing that doesn\'t require a browser.'
  s.files = Dir['CHANGELOG', 'README', 'MIT-LICENSE', 'lib/**/*']
  s.has_rdoc = true
  s.requirements << 'none'
  s.add_dependency('activesupport', '= 2.3.16')
  s.add_dependency('rack', '~> 1.1.0')
  s.require_path = 'lib'
  s.autorequire = 'action_controller'
  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "actionpack"
end
