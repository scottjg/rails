require File.join(File.dirname(__FILE__), 'lib/rails', 'version')
require 'rake'

pkg_build       = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
pkg_version     = Rails::VERSION::STRING + pkg_build

pkg_files = FileList[
  '[a-zA-Z]*',
  'bin/**/*', 
  'builtin/**/*',
  'configs/**/*', 
  'doc/**/*', 
  'dispatches/**/*', 
  'environments/**/*', 
  'helpers/**/*', 
  'generators/**/*', 
  'html/**/*', 
  'lib/**/*'
] - [ 'test' ]

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'rails'
  s.version = pkg_version
  s.summary = "Web-application framework with template engine, control-flow layer, and ORM."
  s.description = <<-EOF
    Rails is a framework for building web-application using CGI, FCGI, mod_ruby, or WEBrick
    on top of either MySQL, PostgreSQL, SQLite, DB2, SQL Server, or Oracle with eRuby- or Builder-based templates.
  EOF

  s.add_dependency('rake', '>= 0.8.3')
  s.add_dependency('activesupport',    '= 2.3.14' + pkg_build)
  s.add_dependency('activerecord',     '= 2.3.14' + pkg_build)
  s.add_dependency('actionpack',       '= 2.3.14' + pkg_build)
  s.add_dependency('actionmailer',     '= 2.3.14' + pkg_build)
  s.add_dependency('activeresource',   '= 2.3.14' + pkg_build)

  s.rdoc_options << '--exclude' << '.'

  s.files = pkg_files
  s.require_path = 'lib'
  s.bindir = "bin"                               # Use these for applications.
  s.executables = ["rails"]

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "rails"
end
