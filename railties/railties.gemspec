require 'rake' # for FileList
require File.join(File.dirname(__FILE__), 'lib/rails', 'version')

PKG_FILES = Rake::FileList[
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

spec = Gem::Specification.new do |s|
  pkg_build       = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
  pkg_name        = 'rails'
  pkg_version     = Rails::VERSION::STRING + pkg_build
  pkg_file_name   = "#{pkg_name}-#{pkg_version}"
  pkg_destination = ENV["RAILS_PKG_DESTINATION"] || "../#{pkg_name}"
  release_name  = "REL #{pkg_version}"


  s.platform = Gem::Platform::RUBY
  s.name = 'rails'
  s.version = pkg_version
  s.summary = "Web-application framework with template engine, control-flow layer, and ORM."
  s.description = <<-EOF
    Rails is a framework for building web-application using CGI, FCGI, mod_ruby, or WEBrick
    on top of either MySQL, PostgreSQL, SQLite, DB2, SQL Server, or Oracle with eRuby- or Builder-based templates.
  EOF

  s.add_dependency('rake', '>= 0.8.3')
  s.add_dependency('activesupport',    '= 2.3.9' + pkg_build)
  s.add_dependency('activerecord',     '= 2.3.9' + pkg_build)
  s.add_dependency('actionpack',       '= 2.3.9' + pkg_build)
  s.add_dependency('actionmailer',     '= 2.3.9' + pkg_build)
  s.add_dependency('activeresource',   '= 2.3.9' + pkg_build)

  s.rdoc_options << '--exclude' << '.'

  s.files = PKG_FILES
  s.require_path = 'lib'
  s.bindir = "bin"                               # Use these for applications.
  s.executables = ["rails"]

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "rails"
end