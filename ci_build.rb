#!/usr/bin/env ruby
require 'fileutils'

include FileUtils

puts "[CruiseControl] Rails build"

build_results = {}

cd 'activesupport' do
  puts
  puts "[CruiseControl] Building ActiveSupport"
  puts
  build_results[:activesupport] = system 'rake'
end

cd 'activerecord' do
  puts
  puts "[CruiseControl] Building ActiveRecord with MySQL"
  puts
  build_results[:activerecord_mysql] = system 'rake test_mysql'
end

cd 'activerecord' do
  puts
  puts "[CruiseControl] Building ActiveRecord with PostgreSQL"
  puts
  build_results[:activerecord_postgresql8] = system 'rake test_postgresql'
end

cd 'activerecord' do
 puts
 puts "[CruiseControl] Building ActiveRecord with SQLite 2"
 puts
 build_results[:activerecord_sqlite] = system 'rake test_sqlite'
end

cd 'activerecord' do
  puts
  puts "[CruiseControl] Building ActiveRecord with SQLite 3"
  puts
  build_results[:activerecord_sqlite3] = system 'rake test_sqlite3'
end

cd 'activemodel' do
  puts
  puts "[CruiseControl] Building ActiveModel"
  puts
  build_results[:activemodel] = system 'rake'
end

cd 'activeresource' do
  puts
  puts "[CruiseControl] Building ActiveResource"
  puts
  build_results[:activeresource] = system 'rake'
end

cd 'actionpack' do
  puts
  puts "[CruiseControl] Building ActionPack"
  puts
  build_results[:actionpack] = system 'rake'
end

cd 'actionmailer' do
  puts
  puts "[CruiseControl] Building ActionMailer"
  puts
  build_results[:actionmailer] = system 'rake'
end

cd 'railties' do
  puts
  puts "[CruiseControl] Building RailTies"
  puts
  build_results[:railties] = system 'rake'
end


puts
puts "[CruiseControl] Build environment:"
puts "[CruiseControl]   #{`cat /etc/issue`}"
puts "[CruiseControl]   #{`uname -a`}"
puts "[CruiseControl]   #{`ruby -v`}"
puts "[CruiseControl]   #{`/usr/bin/mysql --version`}"
puts "[CruiseControl]   #{`/usr/bin/postgres --version`}"
puts "[CruiseControl]   SQLite3: #{`/usr/bin/sqlite2 -version`}"
puts "[CruiseControl]   SQLite3: #{`/usr/bin/sqlite3 -version`}"
puts "[CruiseControl]   Local gems: #{`gem list`}"
puts

failures = build_results.select { |key, value| value == false }

if failures.empty?
  puts
  puts "[CruiseControl] Rails build finished sucessfully"
  exit(0)
else
  puts
  puts "[CruiseControl] Rails build FAILED"
  puts "[CruiseControl] Failed components: #{failures.map { |component| component.first }.join(', ')}"
  exit(-1)
end

