#!/usr/bin/env ruby
require 'fileutils'

class SetupRailsDependencies
  def self.setup
    puts "Setting up Rails build dependencies..."

    # Detect distro, only Gentoo and Debian currently supported
    distro = system('which emerge') ? 'gentoo' : 'debian'

    if distro == 'gentoo'
      packages = %w{
        sqlite
        mysql
        postgresql-server
        fcgi
        memcached
      }
    else
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
    end
    
    # custom pre-package installation
    if distro == 'debian'
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
    end
        
    # Install packages    
    packages.each do |package|
      if distro == 'gentoo'
        run "sudo emerge #{package}" unless system("qlist -I | grep #{package}")
      else
        run "sudo aptitude -y install #{package}" unless ((run "dpkg -l #{package}", false) =~ /ii  #{package}/)
      end
    end
    
    # custom post-package installation
    if distro == 'gentoo'
      run "echo 'Y' | sudo emerge postgresql-server --config"
      run "sudo /etc/init.d/postgresql-8.3 start"
    end

    # start services
    run "sudo /etc/init.d/mysql start"

    # Setup database users for MySQL and PostgreSQL
    run "mysql -uroot -e 'grant all on *.* to rails@localhost;'"
    run "sudo su -l postgres -c 'createuser -s ci'", false

    # Install GemInstaller
    run "sudo gem install geminstaller"

    # Install GemInstaller
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
