$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "composed_of/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "composed_of"
  s.version     = ComposedOf::VERSION
  s.authors     = ["Piotr Sarnacki"]
  s.email       = ["drogus@gmail.com"]
  s.homepage    = "https://github.com/rails/composed_of"
  s.summary     = "Extracted composed_of from rails code base"
  s.description = "Extracted composed_of from rails code base"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.0.beta"
end
