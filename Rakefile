require 'rake'
require 'rdoc/task'

env = %(PKG_BUILD="#{ENV['PKG_BUILD']}") if ENV['PKG_BUILD']

PROJECTS = %w(activesupport railties actionpack actionmailer activeresource activerecord)

Dir["#{File.dirname(__FILE__)}/*/lib/*/version.rb"].each do |version_path|
  require version_path
end

desc 'Run all tests by default'
task :default => :test

%w(test pgem package release gem).each do |task_name|
  desc "Run #{task_name} task for all projects"
  task task_name do
    PROJECTS.each do |project|
      system %(cd #{project} && #{env} #{$0} #{task_name})
    end
  end
end


