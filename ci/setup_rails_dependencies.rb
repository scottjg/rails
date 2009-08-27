#!/usr/bin/env ruby
require 'fileutils'

class SetupRailsDependencies
  def self.setup
    puts "Setting up Rails build dependencies..."

    packages = %w{
      sqlite,
      libsqlite-dev,
      sqlite3,
      libsqlite3-dev,
      mysql-server-5.0,
      libmysqlclient-dev,
      postgresql,
      postgresql-server-dev-8.3,
      libfcgi-dev,
      memcached
    }
    # Install packages using aptitude
    run "sudo aptitude -y install #{packages.join(" ")}"

    # Setup database users for MySQL and PostgreSQL
    run "mysql -uroot -e 'grant all on *.* to rails@localhost;'"
    run "sudo su - postgres -c 'createuser -s ci'"

    # Install and run GemInstaller to get all dependency gems
    run "sudo gem install geminstaller"
    run "sudo geminstaller --config=#{ccrb_project_work}/ci/geminstaller.yml"

    print "\n\nRails build setup script completed.\n"
  end

  def run(cmd)
    puts "Running command: #{cmd}"
    unless system(cmd)
      print "\n\nCommand failed: #{cmd}\n"
      exit $?.to_i
    end
  end
end
 
SetupRailsDependencies.setup
