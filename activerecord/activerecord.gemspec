# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../../RAILS_VERSION",__FILE__)).strip

unless defined?(TEST_ROOT)
  TEST_ROOT = File.expand_path(File.dirname(__FILE__))
  ASSETS_ROOT = TEST_ROOT + "/assets"
  FIXTURES_ROOT = TEST_ROOT + "/fixtures"
  MIGRATIONS_ROOT = TEST_ROOT + "/migrations"
  SCHEMA_ROOT = TEST_ROOT + "/schema"
end

Gem::Specification.new do |s|
 s.platform = Gem::Platform::RUBY
 s.name = 'activerecord'
 s.version = version
 s.summary = "Implements the ActiveRecord pattern for ORM."
 s.description = %q{Implements the ActiveRecord pattern (Fowler, PoEAA) for ORM. It ties database tables and classes together for business objects, like Customer or Subscription, that can find, save, and destroy themselves without resorting to manual SQL.}

 s.files = [ "Rakefile", "install.rb", "README", "RUNNING_UNIT_TESTS", "CHANGELOG" ]
 [ "lib", "test", "examples" ].each do |dir|
   s.files = s.files + Dir.glob( "#{dir}/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
 end

 s.add_dependency('activesupport', version)

 s.files.delete FIXTURES_ROOT + "/fixture_database.sqlite"
 s.files.delete FIXTURES_ROOT + "/fixture_database_2.sqlite"
 s.files.delete FIXTURES_ROOT + "/fixture_database.sqlite3"
 s.files.delete FIXTURES_ROOT + "/fixture_database_2.sqlite3"
 s.require_path = 'lib'

 s.extra_rdoc_files = %w( README )
 s.rdoc_options.concat ['--main',  'README']

 s.author = "David Heinemeier Hansson"
 s.email = "david@loudthinking.com"
 s.homepage = "http://www.rubyonrails.org"
 s.rubyforge_project = "activerecord"
end
