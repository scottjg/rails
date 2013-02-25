require 'rubygems'

require 'date'
require 'rbconfig'
require File.join(File.dirname(__FILE__), 'lib/rails', 'version')

RT_PKG_BUILD = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
RT_PKG_NAME = 'rails'
RT_PKG_VERSION = Rails::VERSION::STRING + RT_PKG_BUILD
RT_PKG_FILE_NAME = "#{RT_PKG_NAME}-#{RT_PKG_VERSION}"
RT_PKG_DESTINATION = ENV["RAILS_PKG_DESTINATION"] || "../#{RT_PKG_NAME}"

RELEASE_NAME = "REL #{RT_PKG_VERSION}"

FILE_LIST = [
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
]
NOT_FILES = [ 'test' ]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'rails'
  s.version = RT_PKG_VERSION
  s.summary = "Web-application framework with template engine, control-flow layer, and ORM."
  s.description = <<-EOF
    Rails is a framework for building web-application using CGI, FCGI, mod_ruby, or WEBrick
    on top of either MySQL, PostgreSQL, SQLite, DB2, SQL Server, or Oracle with eRuby- or Builder-based templates.
  EOF

  s.add_dependency('rake', '>= 0.8.3', '<= 0.9.2.2')
  s.add_dependency('activesupport',    '= 2.3.2' + RT_PKG_BUILD)
  s.add_dependency('activerecord',     '= 2.3.2' + RT_PKG_BUILD)
  s.add_dependency('actionpack',       '= 2.3.2' + RT_PKG_BUILD)
  s.add_dependency('actionmailer',     '= 2.3.2' + RT_PKG_BUILD)
  s.add_dependency('activeresource',   '= 2.3.2' + RT_PKG_BUILD)

  s.rdoc_options << '--exclude' << '.'
  s.has_rdoc = false

  pkg_files = []
  FILE_LIST.each {|pkg| pkg_files += Dir[pkg] }
  NOT_FILES.each {|f| pkg_files.reject! {|pkg| pkg.match f } }
  pkg_files.reject!  { |fn| fn.include? ".svn" }
  s.files = pkg_files
  s.require_path = 'lib'
  s.bindir = "bin"                               # Use these for applications.
  s.executables = ["rails"]
  s.default_executable = "rails"

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"
  s.rubyforge_project = "rails"
end
