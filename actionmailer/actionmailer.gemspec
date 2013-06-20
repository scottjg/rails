# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../../RAILS_VERSION",__FILE__)).strip

Gem::Specification.new do |s|
  s.name = 'actionmailer'
  s.version = version
  s.summary = 'Service layer for easy email delivery and testing.'
  s.description = 'Makes it trivial to test and deliver emails sent from a single service layer.'

  s.author = 'David Heinemeier Hansson'
  s.email = 'david@loudthinking.com'
  s.homepage = 'http://www.rubyonrails.org'

  s.add_dependency('mail', '2.5.4')

  s.require_path = 'lib'

  s.add_dependency 'actionpack', version
end
