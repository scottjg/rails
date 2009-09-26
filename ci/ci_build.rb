#!/usr/bin/env ruby
require 'fileutils'

include FileUtils

puts "[CruiseControl] Rails build"

if ENV['RAILS_CI_PROJECTS']
  puts "[CruiseControl] Building projects: #{ENV['RAILS_CI_PROJECTS']}"
else
  puts "[CruiseControl] Building all projects"
end

build_results = {}
root_dir = File.expand_path(File.dirname(__FILE__) + "/..")

# Requires gem home and path to be writeable and/or overridden to be ~/.gem,
# Will enable when RubyGems supports this properly (in a coming release)
# build_results[:geminstaller] = system 'geminstaller --exceptions'

# for now, use the no-passwd sudoers approach (documented in ci_setup_notes.txt)
# A security hole, but there is nothing valuable on rails CI box anyway.
build_results[:geminstaller] = system "sudo geminstaller --config=#{root_dir}/ci/geminstaller.yml --exceptions"

if ENV['RAILS_CI_PROJECTS'].nil? || ENV['RAILS_CI_PROJECTS'] =~ /activesupport/ 
  cd "#{root_dir}/activesupport" do
    puts
    puts "[CruiseControl] Building ActiveSupport"
    puts
    build_results[:activesupport] = system 'rake'
    build_results[:activesupport_isolated] = system 'rake test:isolated'
  end
end

if ENV['RAILS_CI_PROJECTS'].nil? || ENV['RAILS_CI_PROJECTS'] =~ /activerecord/ 
  rm_f "#{root_dir}/activerecord/debug.log"
  cd "#{root_dir}/activerecord" do
    puts
    puts "[CruiseControl] Building ActiveRecord with MySQL"
    puts
    build_results[:activerecord_mysql] = system 'rake mysql:rebuild_databases && rake test_mysql'
  end

  cd "#{root_dir}/activerecord" do
    puts
    puts "[CruiseControl] Building ActiveRecord with PostgreSQL"
    puts
    build_results[:activerecord_postgresql8] = system 'rake postgresql:rebuild_databases && rake test_postgresql'
  end

  cd "#{root_dir}/activerecord" do
    puts
    puts "[CruiseControl] Building ActiveRecord with SQLite 3"
    puts
    build_results[:activerecord_sqlite3] = system 'rake test_sqlite3'
  end
end

if ENV['RAILS_CI_PROJECTS'].nil? || ENV['RAILS_CI_PROJECTS'] =~ /activemodel/ 
  cd "#{root_dir}/activemodel" do
    puts
    puts "[CruiseControl] Building ActiveModel"
    puts
    build_results[:activemodel] = system 'rake'
  end
end


if ENV['RAILS_CI_PROJECTS'].nil? || ENV['RAILS_CI_PROJECTS'] =~ /activeresource/ 
  rm_f "#{root_dir}/activeresource/debug.log"
  cd "#{root_dir}/activeresource" do
    puts
    puts "[CruiseControl] Building ActiveResource"
    puts
    build_results[:activeresource] = system 'rake'
  end
end

if ENV['RAILS_CI_PROJECTS'].nil? || ENV['RAILS_CI_PROJECTS'] =~ /actionpack/ 
  cd "#{root_dir}/actionpack" do
    puts
    puts "[CruiseControl] Building ActionPack"
    puts
    build_results[:actionpack] = system 'gem bundle && rake'
  end
end

if ENV['RAILS_CI_PROJECTS'].nil? || ENV['RAILS_CI_PROJECTS'] =~ /actionmailer/ 
  cd "#{root_dir}/actionmailer" do
    puts
    puts "[CruiseControl] Building ActionMailer"
    puts
    build_results[:actionmailer] = system 'rake'
  end
end

if ENV['RAILS_CI_PROJECTS'].nil? || ENV['RAILS_CI_PROJECTS'] =~ /railties/ 
  cd "#{root_dir}/railties" do
    puts
    puts "[CruiseControl] Building RailTies"
    puts
    build_results[:railties] = system 'rake'
  end
end

puts
puts "[CruiseControl] Build environment:"
puts "[CruiseControl]   #{`cat /etc/issue`}"
puts "[CruiseControl]   #{`uname -a`}"
puts "[CruiseControl]   #{`ruby -v`}"
puts "[CruiseControl]   #{`mysql --version`}"
puts "[CruiseControl]   #{`pg_config --version`}"
puts "[CruiseControl]   SQLite3: #{`sqlite3 -version`}"
`gem env`.each_line {|line| print "[CruiseControl]   #{line}"}
puts "[CruiseControl]   Local gems:"
`gem list`.each_line {|line| print "[CruiseControl]     #{line}"}

failures = build_results.select { |key, value| value == false }

if failures.empty?
  puts
  puts "[CruiseControl] Rails build finished sucessfully"
  exit(0)
else
  puts
  puts "[CruiseControl] Rails build FAILED"
  puts "[CruiseControl] Failed projects: #{failures.map { |projects| projects.first }.join(', ')}"
  exit(-1)
end

