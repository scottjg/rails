Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'actionpack'
  s.version = '2.3.14'
  s.summary = "Customised ActionPack for REMS3." 
  s.files = Dir['CHANGELOG', 'README', 'MIT-LICENSE', 'lib/**/*']
  s.has_rdoc = true
  s.requirements << 'none'
  s.add_dependency('activesupport', '= 2.3.14')
  s.add_dependency('rack', '~> 1.1.0')
  s.require_path = 'lib'
  s.autorequire = 'action_controller'
end
