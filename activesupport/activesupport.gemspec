Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = "activesupport"
  s.version = "2.3.16"
  s.summary = "Customised ActiveSupport for REMS3." 
  s.description = 'Utility library which carries commonly used classes and goodies from the Rails framework'
  s.files = Dir['CHANGELOG', 'README', 'lib/**/*']
  s.require_path = 'lib'
  s.has_rdoc = true
  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "activesupport"
end
