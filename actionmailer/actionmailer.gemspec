# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../../RAILS_VERSION",__FILE__)).strip

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'actionmailer'
  s.summary = "Service layer for easy email delivery and testing."
  s.description = %q{Makes it trivial to test and deliver emails sent from a single service layer.}
  s.version = version

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.rubyforge_project = "actionmailer"
  s.homepage = "http://www.rubyonrails.org"

  s.add_dependency('actionpack', version)
  s.add_dependency('mail', '2.4.4')

  s.requirements << 'none'
  s.require_path = 'lib'

  s.files = [ "Rakefile", "install.rb", "README", "CHANGELOG", "MIT-LICENSE" ]
  s.files = s.files + Dir.glob( "lib/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
  s.files = s.files + Dir.glob( "test/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
end