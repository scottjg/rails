Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'activesupport'
  s.version = '2.3.17'
  s.summary = 'Support and utility classes used by the Rails framework.'
  s.description = 'Utility library which carries commonly used classes and goodies from the Rails framework'
  s.files = Dir['CHANGELOG', 'README', 'lib/**/*']
  s.require_path = 'lib'
  s.has_rdoc = true
  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "activesupport"
end
