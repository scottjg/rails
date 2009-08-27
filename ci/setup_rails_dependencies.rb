#!/usr/bin/env ruby
require 'fileutils'

class SetupRailsDependencies
  def self.setup
    puts "Setting up Rails build dependencies..."

    packages = %w{
      sqlite
      libsqlite-dev
      sqlite3
      libsqlite3-dev
      mysql-server-5.0
      libmysqlclient-dev
      postgresql
      postgresql-server-dev-8.3
      libfcgi-dev
      memcached
    }
    # Install packages using aptitude
    run "sudo aptitude -y install #{packages.join(" ")}"

    # start services
    run "sudo /etc/init.d/mysql start"

    # Setup database users for MySQL and PostgreSQL
    run "mysql -uroot -e 'grant all on *.* to rails@localhost;'"
    run "sudo su - postgres -c 'createuser -s ci'", false

    # Install GemInstaller
    run "sudo gem install geminstaller"

    print "\n\nRails build setup script completed.\n"
  end

  def self.run(cmd, fail_on_error = true)
    puts "Running command: #{cmd}"
    output = `#{cmd}`
    puts output
    if !$?.success? and fail_on_error
      print "\n\nCommand failed: #{cmd}\n"
      exit $?.to_i
    end
    output
  end
end
 
SetupRailsDependencies.setup
