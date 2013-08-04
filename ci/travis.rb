#!/usr/bin/env ruby
require 'fileutils'
include FileUtils

commands = [
  'sudo sysctl -w kernel.shmmax=268435456',
  'sudo /usr/bin/mysqld_safe &',
  'sleep 3',
  'sudo cat /etc/mysql/mysql_grants.sql | sudo /usr/bin/mysql -u root',
  'sudo service postgresql start',
  'mysql -e "create database activerecord_unittest;" -u rails',
  'mysql -e "create database activerecord_unittest2;" -u rails',
  'psql  -c "create database activerecord_unittest;" -U postgres',
  'psql  -c "create database activerecord_unittest2;" -U postgres'
]

commands.each do |command|
  system("#{command} > /dev/null 2>&1")
end

class Build
  MAP = {
    'railties' => 'railties',
    'ap'   => 'actionpack',
    'am'   => 'actionmailer',
    'amo'  => 'activemodel',
    'as'   => 'activesupport',
    'ar'   => 'activerecord',
    'av'   => 'actionview'
  }

  attr_reader :component, :options

  def initialize(component, options = {})
    @component = component
    @options = options
  end

  def run!(options = {})
    self.options.update(options)
    Dir.chdir(dir) do
      announce(heading)
      rake(*tasks)
    end
  end

  def announce(heading)
    puts "\n\e[1;33m[Travis CI] #{heading}\e[m\n"
  end

  def heading
    heading = [gem]
    heading << "with #{adapter}" if activerecord?
    heading << "in isolation" if isolated?
    heading.join(' ')
  end

  def tasks
    if activerecord?
      ['mysql:rebuild_databases', "#{adapter}:#{'isolated_' if isolated?}test"]
    else
      ["test#{':isolated' if isolated?}"]
    end
  end

  def key
    key = [gem]
    key << adapter if activerecord?
    key << 'isolated' if isolated?
    key.join(':')
  end

  def activerecord?
    gem == 'activerecord'
  end

  def isolated?
    options[:isolated]
  end

  def gem
    MAP[component.split(':').first]
  end
  alias :dir :gem

  def adapter
    component.split(':').last
  end

  def rake(*tasks)
    tasks.each do |task|
      cmd = "bundle exec rake #{task}"
      puts "Running command: #{cmd}"
      return false unless system(cmd)
    end
    true
  end
end

results = {}

ENV['GEM'].split(',').each do |gem|
  [false, true].each do |isolated|
    next if gem == 'railties' && isolated

    build = Build.new(gem, :isolated => isolated)
    results[build.key] = build.run!

  end
end

# puts
# puts "Build environment:"
# puts "  #{`cat /etc/issue`}"
# puts "  #{`uname -a`}"
# puts "  #{`ruby -v`}"
# puts "  #{`mysql --version`}"
# puts "  #{`pg_config --version`}"
# puts "  SQLite3: #{`sqlite3 -version`}"
# `gem env`.each_line {|line| print "   #{line}"}
# puts "   Bundled gems:"
# `bundle show`.each_line {|line| print "     #{line}"}
# puts "   Local gems:"
# `gem list`.each_line {|line| print "     #{line}"}

failures = results.select { |key, value| !value  }

if failures.empty?
  puts
  puts "Rails build finished successfully"
  exit(true)
else
  puts
  puts "Rails build FAILED"
  puts "Failed components: #{failures.map { |component| component.first }.join(', ')}"
  exit(false)
end
