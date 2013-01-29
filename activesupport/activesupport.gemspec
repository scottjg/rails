# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../../RAILS_VERSION",__FILE__)).strip

Gem::Specification.new do |s|
  s.name = 'activesupport'
  s.version = version
  s.summary = 'Support and utility classes used by the Rails framework.'
  s.description = 'Utility library which carries commonly used classes and goodies from the Rails framework'

  s.author = 'David Heinemeier Hansson'
  s.email = 'david@loudthinking.com'
  s.homepage = 'http://www.rubyonrails.org'

  s.require_path = 'lib'
end
