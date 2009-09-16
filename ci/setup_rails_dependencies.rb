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
    
    # custom pre-package installation
    pw_file = <<-eos
Name: mysql-server/root_password
Template: mysql-server/root_password
Value: 
Owners: mysql-server-5.0
Flags: seen

Name: mysql-server/root_password_again
Template: mysql-server/root_password_again
Value: 
Owners: mysql-server-5.0
Flags: seen
    eos

    run "sudo su -c 'echo \"#{pw_file}\" > /var/cache/debconf/passwords.dat'"
        
    # Install packages    
    packages.each do |package|
      run "sudo aptitude -y install #{package}" unless ((run "dpkg -l #{package}", false) =~ /ii  #{package}/)
    end
    
    # start services
    run "sudo /etc/init.d/mysql start"

    # Setup database users for MySQL and PostgreSQL
    run "mysql -uroot -e 'grant all on *.* to rails@localhost;'"
    run "sudo su -l postgres -c 'createuser -s ci'", false

    # Install GemInstaller
    run "sudo gem install geminstaller"

    # Install Bundler
    run "sudo gem install bundler"

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
