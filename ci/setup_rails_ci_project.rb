#!/usr/bin/env ruby
require 'fileutils'

class SetupRailsCiProject
  def self.setup
    ccrb_project = ENV['CCRB_PROJECT'] || 'rails'
    rails_working_copy_dir = "#{ENV['HOME']}/.cruise/projects/#{ccrb_project}/work"
    rails_github_url = ENV['RAILS_GITHUB_URL'] || 'git://github.com/rails/rails.git'

    puts "Creating CruiseControl.rb project for #{ccrb_project}..."

    # Create the project in CruiseControl.rb
    run "~/ccrb/cruise add #{ccrb_project} -s git -r #{rails_github_url}"

    # Copy the site config and project configs
    FileUtils.cp(
      ["#{rails_working_copy_dir}/ci/site_config.rb","#{rails_working_copy_dir}/ci/site.css"],
      "#{ENV['HOME']}/.cruise/site_config.rb"
    )
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
