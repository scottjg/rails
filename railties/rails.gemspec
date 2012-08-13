# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../../RAILS_VERSION",__FILE__)).strip

Gem::Specification.new do |s|
  s.name = "rails"
  s.version = version
  s.summary = "Web-application framework with template engine, control-flow layer, and ORM."
  s.description = "    Rails is a framework for building web-application using CGI, FCGI, mod_ruby, or WEBrick\n    on top of either MySQL, PostgreSQL, SQLite, DB2, SQL Server, or Oracle with eRuby- or Builder-based templates.\n"

  s.required_rubygems_version = ">= 1.8.11"

  s.author = "David Heinemeier Hansson"
  s.email = "david@loudthinking.com"
  s.homepage = "http://www.rubyonrails.org"

  s.date = "2012-04-03"
  s.executables = ["rails"]
  s.files = ["bin/rails"]
  s.rdoc_options = ["--exclude", "."]
  s.require_paths = ["lib"]
  s.rubyforge_project = "rails"
  s.rubygems_version = "1.8.24"

  s.add_dependency('rake', [">= 0.8.3"])
  s.add_dependency('activesupport', version)
  s.add_dependency('activerecord', version)
  s.add_dependency('actionpack', version)
  s.add_dependency('actionmailer', version)
  s.add_dependency('activeresource', version)
end
