#!/usr/bin/env ruby

class SetupRailsCiProject
  def self.setup
    
    puts "Setting up Rails CI project(s) in CruiseControl.rb..."

    rails_git_branches = (ENV['RAILS_GIT_BRANCHES'].to_s == '' ? 'master' : ENV['RAILS_GIT_BRANCHES']).split(',')
    rails_ci_projects = (ENV['RAILS_CI_PROJECTS'].to_s == '' ? 'rails' : ENV['RAILS_CI_PROJECTS']).split(',')
    rails_git_repo_url = ENV['RAILS_GIT_REPO_URL'].to_s == '' ? 'git://github.com/rails/rails.git' : ENV['RAILS_GIT_REPO_URL'] 
    ccrb_data_dir = "#{ENV['HOME']}/.cruise"
    ccrb_projects_dir = "#{ccrb_data_dir}/projects"

    first_rails_working_copy_dir = nil
    rails_ci_projects.each do |rails_ci_project|
      rails_git_branches.each do |rails_branch|
        ccrb_project = "#{rails_ci_project}-#{rails_branch}-ruby-#{RUBY_VERSION.gsub('.','-')}"
        ccrb_project_dir = "#{ccrb_projects_dir}/#{ccrb_project}"
        rails_working_copy_dir = "#{ccrb_project_dir}/work"
        first_rails_working_copy_dir ||= rails_working_copy_dir
        if File.exist?(ccrb_project_dir)
          puts "CruiseControl.rb project already exist at directory at #{ccrb_project_dir}, NOT recreating it..."
        else
          puts "Creating CruiseControl.rb project for project '#{ccrb_project}'..."
          run "#{ENV['HOME']}/ccrb/cruise add #{ccrb_project} -b #{rails_branch} -s git -r #{rails_git_repo_url}"

          puts "Symlinking Rails' CruiseControl.rb project configuration for project '#{ccrb_project}'..."
          run "ln -s -f #{rails_working_copy_dir}/ci/cruise_config.rb #{ccrb_project_dir}/cruise_config.rb"
        end
      end
    end
    
    puts "Copying CruiseControl.rb site configuration files..."
    run "cp #{first_rails_working_copy_dir}/ci/site_config.rb #{ccrb_data_dir}"
    run "cp #{first_rails_working_copy_dir}/ci/site.css #{ccrb_data_dir}"

    puts "(Re)starting CruiseControl.rb to start builders for new project(s)..."
    run "/etc/init.d/cruise restart"
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
