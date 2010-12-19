# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{activesupport}
  s.version = "2.3.10.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Heinemeier Hansson"]
  s.date = %q{2010-10-14}
  s.description = %q{Utility library which carries commonly used classes and goodies from the Rails framework}
  s.email = %q{david@loudthinking.com}
  s.homepage = %q{http://www.rubyonrails.org}
  s.files = Dir.glob("{activesupport/bin,activesupport/lib}/**/*") + %w(activesupport/MIT-LICENSE activesupport/README activesupport/CHANGELOG)
  s.require_paths = ["activesupport/lib"]
  s.rubyforge_project = %q{activesupport}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Support and utility classes used by the Rails framework.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
