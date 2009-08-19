#!/usr/bin/env ruby
require 'fileutils'
require 'yaml'

class RailsDependencies
  def setup
    home =                ENV['HOME']
    ccrb_user =           ENV['CCRB_USER']           || 'ci'
    ccrb_home =           ENV['CCRB_HOME']           || "#{home}/ccrb"
    ccrb_project_name =   ENV['CCRB_PROJECT']        || 'rails'
    ccrb_source_control = ENV['CCRB_SOURCE_CONTROL'] || 'git'
    ccrb_repository =     ENV['CCRB_REPOSITORY']     || 'git://github.com/rails/rails.git'
    ccrb_project_work = "#{home}/.cruise/projects/#{ccrb_project_name}/work"

    puts "Rails build setup script starting"
    puts "Please be patient, this will take a few minutes..."

    # Create the project in CruiseControl.rb
    run "#{ccrb_home}/cruise add #{ccrb_project_name} -s #{ccrb_source_control} -r #{ccrb_repository}"

    # Copy down the site and project configs
    FileUtils.cp("#{ccrb_project_work}/ci/site_config.rb", "#{home}/.cruise/site_config.rb")
    FileUtils.cp("#{ccrb_project_work}/ci/cruise_config.rb", "#{home}/.cruise/projects/#{ccrb_project_name}")

    # Load packages to install from dependencies config file
    @packages = YAML.load_file("#{ccrb_project_work}/ci/rails_dependencies.yml")

    # Install packages using aptitude
    install_packages_for :sqlite
    install_packages_for :sqlite3
    install_packages_for :mysql
    install_packages_for :postgresql
    install_packages_for :fcgi
    install_packages_for :memcached

    # Setup database users for MySQL and PostgreSQL
    run "mysql -uroot -e 'grant all on *.* to rails@localhost;'"
    sudo "su - postgres -c 'createuser -s ci'"

    # Install and run GemInstaller to get all dependency gems
    sudo "gem install geminstaller"
    sudo "geminstaller --config=#{ccrb_project_work}/ci/geminstaller.yml"

    # Create ActiveRecord test databases for MySQL and PostgreSQL
    run "rake -f \"#{ccrb_project_work}/activerecord/Rakefile\" mysql:build_databases"
    run "rake -f \"#{ccrb_project_work}/activerecord/Rakefile\" postgresql:build_databases"

    print "\n\nRails build setup script completed.\n"
  end

  def install_packages_for(key)
    packages = @packages[key.to_s]
    sudo "aptitude -y install #{packages.join(" ")}" if packages
  end

  private
    def run(cmd)
      puts "Running command: #{cmd}"
      unless system(cmd)
        print "\n\nCommand failed: #{cmd}\n"
        exit $?.to_i
      end

      $?.to_i
    end

    def sudo(cmd)
      run "sudo #{cmd}"
    end
end
 
RailsDependencies.new.setup
