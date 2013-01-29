Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'activerecord'
  s.version = '2.3.16'
  s.summary = "Customised ActiveRecord for REMS3." 
  s.description = 'Implements the ActiveRecord pattern (Fowler, PoEAA) for ORM. It ties database tables and classes together for business objects, like Customer or Subscription, that can find, save, and destroy themselves without resorting to manual SQL.'
  s.files = Dir['CHANGELOG', 'README', 'examples/**/*', 'lib/**/*'] 
  s.add_dependency('activesupport', '= 2.3.16') 
  s.require_path = 'lib'
  s.autorequire = 'active_record' 
  s.has_rdoc = true
  s.extra_rdoc_files = %w( README )
  s.rdoc_options.concat ['--main',  'README']
  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "activerecord"
end
