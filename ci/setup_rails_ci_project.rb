#!/usr/bin/env ruby

class SetupRailsCiProject
  def self.setup
    ccrb_project = ENV['CCRB_PROJECT'] || 'rails'
    ccrb_rails_project_dir = "#{ENV['HOME']}/.cruise/projects/#{ccrb_project}"
    rails_working_copy_dir = "#{ccrb_rails_project_dir}/work"
    rails_git_repo_url = ENV['RAILS_GIT_REPO_URL'] || 'git://github.com/rails/rails.git'

    puts "Creating CruiseControl.rb project for #{ccrb_project}..."

    # Create the project in CruiseControl.rb
    if !File.exist?(rails_working_copy_dir)
      run "#{ENV['HOME']}/ccrb/cruise add #{ccrb_project} -s git -r #{rails_git_repo_url}"
    end

    # Copy the site config and css
    run "cp #{rails_working_copy_dir}/ci/site_config.rb #{ENV['HOME']}/.cruise/"
    run "cp #{rails_working_copy_dir}/ci/site.css #{ENV['HOME']}/.cruise/"

    # Symlink the cruise config file
    run "ln -s -f #{rails_working_copy_dir}/ci/cruise_config.rb #{ccrb_rails_project_dir}/cruise_config.rb"
    
    # Start cruise
    run "/etc/init.d/cruise start"    
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
 
SetupRailsCiProject.setup
