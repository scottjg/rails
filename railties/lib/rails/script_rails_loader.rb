require 'pathname'

module Rails
  module ScriptRailsLoader
    SCRIPT_RAILS = File.join('script', 'rails')
    # Check for encrypted appliance
    if File.exists?("/var/www/miq/vmdb") && `file -b #{SCRIPT_RAILS}` =~ /^ELF /
      RUBY = nil
    else
      RUBY = File.join(*RbConfig::CONFIG.values_at("bindir", "ruby_install_name")) + RbConfig::CONFIG["EXEEXT"]
    end

    def self.exec_script_rails!
      cwd = Dir.pwd
      return unless in_rails_application? || in_rails_application_subdirectory?
      exec *([RUBY, SCRIPT_RAILS, *ARGV].compact) if in_rails_application?
      Dir.chdir("..") do
        # Recurse in a chdir block: if the search fails we want to be sure
        # the application is generated in the original working directory.
        exec_script_rails! unless cwd == Dir.pwd
      end
    rescue SystemCallError
      # could not chdir, no problem just return
    end

    def self.in_rails_application?
      File.exists?(SCRIPT_RAILS)
    end

    def self.in_rails_application_subdirectory?(path = Pathname.new(Dir.pwd))
      File.exists?(File.join(path, SCRIPT_RAILS)) || !path.root? && in_rails_application_subdirectory?(path.parent)
    end
  end
end