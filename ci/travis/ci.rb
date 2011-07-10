#!/usr/bin/env ruby
require 'fileutils'
include FileUtils

commands = [
  'mysql -e "create database activerecord_unittest;"',
  'mysql -e "create database activerecord_unittest2;"',
  'psql  -c "create database activerecord_unittest;" -U postgres > /dev/null',
  'psql  -c "create database activerecord_unittest2;" -U postgres > /dev/null'
]
commands.each do |command|
  system(command)
end

def rake(*tasks)
  tasks.each do |task|
    cmd = "bundle exec rake #{task}"
    puts "Running command: #{cmd}"
    return false unless system(cmd)
  end
  true
end

RESULTS  = {}
DEFAULTS = { :normal => 'test', :isolated => 'test:isolated' }

def isolated?
  ENV['ISOLATED'] == 'true'
end

def identity_map?
  ENV['IM'] == 'true'
end

def announce(section)
  puts
  puts "\e[1;33m[Travis CI] #{section}\e[m"
  puts
end

def build(key, options = {})
  config  = DEFAULTS.merge(options)
  name    = config[:name] || key
  dir     = config[:dir] || key.to_s
  command = config[:command] || config[isolated? ? :isolated : :normal]

  cd(dir) do
    announce name
    RESULTS[key] = rake(*Array(command))
  end if command
end

def build_active_record(adapter, options = {})
  if identity_map?
    ENV['IM'] = 'true'
    name = "activerecord with #{adapter} IM enabled"
    key  = :"activerecord_#{adapter}_IM"
  else
    ENV['IM'] = 'false'
    name = "activerecord with #{adapter} IM disabled"
    key  = :"activerecord_#{adapter}"
  end
  command = 'mysql:rebuild_databases', "#{adapter}:#{'isolated_' if isolated?}test"
  build(key, :name => name, :command => command, :dir => 'activerecord')
end

unless identity_map?
  build :activesupport
  build :railties
  build :actionpack
  build :actionmailer
  build :activemodel
  build :activeresource
end

# We currently have issues with configuring postgres inside vagrant properly so
# that it supports the required number of connections for the rails test suite
# (which seems to be huge). So we have to leave postgres out until this has been
# fixed.
#
# :postgresql

[:mysql, :mysql2, :sqlite3].each do |adapter|
  build_active_record adapter
end

puts
puts "Build environment:"
puts "  #{`cat /etc/issue`}"
puts "  #{`uname -a`}"
puts "  #{`ruby -v`}"
puts "  #{`mysql --version`}"
# puts "  #{`pg_config --version`}"
puts "  SQLite3: #{`sqlite3 -version`}"
`gem env`.each_line {|line| print "   #{line}"}
puts "   Bundled gems:"
`bundle show`.each_line {|line| print "     #{line}"}
puts "   Local gems:"
`gem list`.each_line {|line| print "     #{line}"}

failures = RESULTS.select { |key, value| value == false }

if failures.empty?
  puts
  puts "Rails build finished sucessfully"
  exit(true)
else
  puts
  puts "Rails build FAILED"
  puts "Failed components: #{failures.map { |component| component.first }.join(', ')}"
  exit(false)
end
