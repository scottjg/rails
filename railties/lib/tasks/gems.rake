desc "List the gems that this rails application depends on"
task :gems => 'gems:base' do
  Rails.configuration.gems.each do |gem|
    print_gem_status(gem)
  end
  puts
  puts "I = Installed"
  puts "F = Frozen"
  puts "R = Framework (loaded before rails starts)"
end

namespace :gems do
  task :base do
    $gems_rake_task = true
    require 'rubygems'
    require 'rubygems/gem_runner'
    Rake::Task[:environment].invoke
  end

  desc "Build any native extensions for unpacked gems"
  task :build do
    $gems_build_rake_task = true
    Rake::Task['gems:unpack'].invoke
    Rails.configuration.gems.each { |gem| gem.build }
  end

  desc "Installs all required gems."
  task :install => :base do
    Rails.configuration.gems.each { |gem| gem.install }
  end

  desc "Unpacks all required gems into vendor/gems."
  task :unpack => :install do
    Rails.configuration.gems.each { |gem| gem.unpack }
  end

  desc "Regenerate gem specifications in correct format."
  task :refresh => :base do
    Rails.configuration.gems.each { |gem| gem.refresh }
  end

  # deprecated
  namespace :install do
    task :dependencies do
      puts "DEPRECATED: gems:install:dependencies is no longer necessary."
      puts "  Use gems:install instead."
      Rake::Task['gems:install'].invoke
    end
  end

  # deprecated
  namespace :unpack do
    task :dependencies do
      puts "DEPRECATED: gems:unpack:dependencies is no longer necessary."
      puts "  Use gems:unpack instead."
      Rake::Task['gems:unpack'].invoke
    end
  end
end

def print_gem_status(gem, indent=1)
  code = case
    when gem.framework_gem? then 'R'
    when gem.frozen?        then 'F'
    when gem.installed?     then 'I'
    else                         ' '
  end
  puts "   "*(indent-1)+" - [#{code}] #{gem.name} #{gem.requirement.to_s}"
  gem.dependencies.each { |g| print_gem_status(g, indent+1) }
end
