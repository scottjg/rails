Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'id-validations'
  s.version     = '0.1'
  s.summary     = 'Validations for id models, extracted from Active Model'
  s.description = 'Because they\'re immutable, id models don\'t play too well with vanilla Active Model. This fork makes the two work together.'

  s.required_ruby_version = '>= 1.9.3'

  s.license = 'MIT'

  s.authors  = ['David Heinemeier Hansson', 'Russell Dunphy']
  s.email    = ['david@loudthinking.com', 'russell@russelldunphy.com']
  s.homepage = 'http://www.rubyonrails.org'

  s.files        = Dir['CHANGELOG.md', 'MIT-LICENSE', 'README.rdoc', 'lib/**/*']
  s.require_path = 'lib'

  s.add_dependency 'activesupport'

  s.add_dependency 'builder', '~> 3.1.0'
end
