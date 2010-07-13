require 'set'
require 'active_support/inflector'
require 'active_support/deprecation'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/introspection'
require 'active_support/core_ext/module/anonymous'

module ActiveSupport # :nodoc:
  # Documentation goes here.
  module Dependencies
    module Tools # :nodoc:
      def self.included(base) # :nodoc:
        base.extend(self)
      end

      # Convert the provided const desc to a qualified constant name (as a string).
      # A module, class, symbol, or string may be provided.
      def to_constant_name(desc) #:nodoc:
        name = case desc
        when String then desc.sub(/^(::)?(Object)?::/, '')
        when Symbol then desc.to_s
        when Module, Constant
          desc.name.presence ||
          raise(ArgumentError, "Anonymous modules have no name to be referenced by")
        else raise TypeError, "Not a valid constant descriptor: #{desc.inspect}"
        end
      end

      def qualified_const_defined?(name)
        !!qualified_const(name)
      end

      def qualified_const(name)
        names = to_constant_name(name).split("::")
        names.inject(Object) do |mod, name|
          return unless local_const_defined?(mod, name)
          mod.const_get(name)
        end
      end

      # Does the provided path_suffix correspond to an autoloadable module?
      # Instead of returning a boolean, the autoload base for this module is returned.
      def autoloadable_module?(path_suffix)
        Dependencies.autoload_paths.each do |load_path|
          return load_path if File.directory? File.join(load_path, path_suffix)
        end
        nil
      end

      def trace
        caller.reject {|l| l =~ %r{#{Regexp.escape(__FILE__)}} }
      end

      def name_error(name)
        NameError.new("uninitialized constant #{name}").tap do |name_error|
          name_error.set_backtrace(trace)
        end
      end

      def load?
        Dependencies.mechanism == :load
      end

      def logger
        return super if self == Dependencies
        Dependencies.logger
      end

      def log_activity?
        return super if self == Dependencies
        Dependencies.log_activity
      end

      def autoloaded_constants
        return super if self == Dependencies
        Dependencies.autoloaded_constants
      end

      def load_once_path?(path)
        Dependencies.autoload_once_paths.any? { |base| path.starts_with? base }
      end

      def require_or_load(file_name, const_path = nil)
        return super if self == Dependencies
        Dependencies.require_or_load(file_name, const_path)
      end

      # Given +path+, a filesystem path to a ruby file, return an array of constant
      # paths which would cause Dependencies to attempt to load this file.
      def loadable_constants_for_path(path, bases = autoload_paths)
        path = $1 if path =~ /\A(.*)\.rb\Z/
        expanded_path = File.expand_path(path)
        paths = []

        bases.each do |root|
          expanded_root = File.expand_path(root)
          next unless %r{\A#{Regexp.escape(expanded_root)}(/|\\)} =~ expanded_path

          nesting = expanded_path[(expanded_root.size)..-1]
          nesting = nesting[1..-1] if nesting && nesting[0] == ?/
          next if nesting.blank?

          paths << nesting.camelize
        end

        paths.uniq!
        paths
      end

      # Search for a file in autoload_paths matching the provided suffix.
      def search_for_file(path_suffix)
        path_suffix = path_suffix.sub(/(\.rb)?$/, ".rb")
        Dependencies.autoload_paths.each do |root|
          path = File.join(root, path_suffix)
          return path if File.file? path
        end
        nil # Gee, I sure wish we had first_match ;-)
      end

      if Module.method(:const_defined?).arity == 1
        # Does this module define this constant?
        # Wrapper to accommodate changing Module#const_defined? in Ruby 1.9
        def local_const_defined?(mod, const)
          mod.const_defined?(const)
        end
      else
        def local_const_defined?(mod, const) #:nodoc:
          mod.const_defined?(const, false)
        end
      end

      def loaded?(file)
        Dependencies.loaded.include? File.expand_path(file)
      end

      # Return the constant path for the provided parent and constant name.
      def qualified_name_for(mod, name)
        mod_name = to_constant_name mod
        mod_name == "Object" ? name.to_s : "#{mod_name}::#{name}"
      end

      protected

      def log_call(*args)
        if logger && log_activity?
          arg_str = args.collect { |arg| arg.inspect } * ', '
          /in `([a-z_\?\!]+)'/ =~ caller(1).first
          selector = $1 || '<unknown>'
          log "called #{selector}(#{arg_str})"
        end
      end

      def log(msg)
        if logger && log_activity?
          logger.debug "Dependencies: #{msg}"
        end
      end
    end

    class WatchStack < Array
      include Tools

      def initialize
        @mutex = Mutex.new
      end

      def self.locked(*methods)
        methods.each { |m| class_eval "def #{m}(*) lock { super } end", __FILE__, __LINE__ }
      end

      def get(key)
        (val = assoc(key)) ? val[1] : []
      end

      locked :concat, :each, :delete_if, :<<

      def new_constants_for(frames)
        constants = []
        frames.each do |mod_name, prior_constants|
          mod = Inflector.constantize(mod_name) if qualified_const_defined?(mod_name)
          next unless mod.is_a?(Module)

          new_constants = mod.local_constant_names - prior_constants
          get(mod_name).concat(new_constants)

          new_constants.each do |suffix|
            constants << ([mod_name, suffix] - ["Object"]).join("::")
          end
        end
        constants
      end  

      # Add a set of modules to the watch stack, remembering the initial constants
      def add_modules(modules)
        list = modules.map do |desc|
          name = to_constant_name(desc)
          consts = qualified_const_defined?(name) ? Inflector.constantize(name).local_constant_names : []
          [name, consts]
        end
        concat(list)
        list
      end

      def lock
        @mutex.synchronize { yield self }
      end
    end

    module Strategies # :nodoc:
      module World
      end

      module Sloppy
        include World
      end

      module MonkeyPatch
      end
    end

    class Constant
      extend Enumerable
      include Tools

      mattr_accessor :map
      self.map ||= {}

      def self.available?(name)
        map.include? to_constant_name(name)
      end

      def self.new(name)
        return name if Constant === name
        name = to_constant_name(name)
        map[name] ||= super
      end

      class << self
        alias [] new
      end

      attr_reader :name, :constant, :parent, :local_name

      def initialize(name)
        @name = name
        if name =~ /::([^:]+)\Z/
          @parent, @local_name = Constant[$`], $1
        elsif object?
          @parent, @local_name = self, 'Object'
        else
          @parent, @local_name = Constant[Object], name
        end
        @constant = qualified_const
      end

      def qualified_name_for(mod, name = nil)
        mod, name = self, mod unless name
        super(mod, name)
      end

      def qualified_const_defined?(desc = name)
        super
      end

      def qualified_const(desc = name)
        super
      end

      def update
        @constant = qualified_const || constant
      end

      def object?
        name == 'Object'
      end

      def active?
        qualified_const == constant
      end

      def active!
        unless active?
          raise ArgumentError, "A copy of #{name} has been removed from the module tree but is still active!"
        end
      end

      def autoloaded?
        qualified_const_defined? and autoloaded_constants.include?(name)
      end

      def unloadable!
        Dependencies.explicitly_unloadable_constants << self
        @unloadable = true
      end

      def unloadable?
        return true if @unloadable or autoloaded?
        return false unless @unloadable.nil?
        @unloadable = Dependencies.explicitly_unloadable_constants.any? do |desc|
          Constant[desc] == self
        end
      end

      def remove
        parent.remove_constant(local_name) if qualified_const_defined?
      end

      def remove_constant(const_name)
        constant.send(:remove_const, const_name)
      end

      def local_const_defined?(mod, name = nil)
        mod, name = constant, mod unless name
        super(mod, name)
      end

      def load_constant(const_name)
        log_call const_name
        active!

        complete_name = qualified_name_for(const_name)
        path_suffix   = complete_name.underscore
        file_path     = search_for_file(path_suffix)

        if file_path and not loaded?(file_path)
          require_or_load file_path
          raise LoadError, "Expected #{file_path} to define #{qualified_name}" unless local_const_defined?(const_name) 
        elsif base_path = autoloadable_module?(path_suffix)
          constant.const_set(const_name, Module.new)
          autoloaded_constants << complete_name unless Dependencies.autoload_once_paths.include?(base_path)
        elsif !object? and not constant.parents.any? { |p| local_const_defined?(p, const_name) }
          return load_parent_constant(const_name, complete_name)
        else
          raise name_error(complete_name)
        end

        Constant[complete_name].update
      end

      def load_parent_constant(const_name, complete_name)
        parent.load_constant(const_name)
      rescue NameError => e
        raise unless e.missing_name? qualified_name_for(parent, const_name)
        raise name_error(complete_name)
      end

      alias get constant
      #Deprecation.deprecate_methods self, :get
    end

    module Hooks
      module Object
        def self.exclude_from(base)
          #base.class_eval { define_method(:load, Kernel.instance_method(:load)) }
        end

        def require_dependency(file_name, message = "No such file to load -- %s")
          unless file_name.is_a?(String)
            raise ArgumentError, "the file name must be a String -- you passed #{file_name.inspect}"
          end

          Dependencies.depend_on(file_name, false, message)
        end

        # Mark the given constant as unloadable. Unloadable constants are removed each
        # time dependencies are cleared.
        #
        # Note that marking a constant for unloading need only be done once. Setup
        # or init scripts may list each unloadable constant that may need unloading;
        # each constant will be removed for every subsequent clear, as opposed to for
        # the first clear.
        #
        # The provided constant descriptor may be a (non-anonymous) module or class,
        # or a qualified constant name as a string or symbol.
        #
        # Returns true if the constant was not previously marked for unloading, false
        # otherwise.
        def unloadable(const_desc)
          Constant[const_desc].unloadable!
        end
      end

      module Module
        def self.append_features(base)
          base.class_eval do
            # Emulate #exclude via an ivar
            return if defined?(@_const_missing) && @_const_missing
            @_const_missing = instance_method(:const_missing)
            remove_method(:const_missing)
          end
          super
        end

        def self.exclude_from(base)
          #base.class_eval do
          #  define_method :const_missing, @_const_missing
          #  @_const_missing = nil
          #end
        end

        # Use const_missing to autoload associations so we don't have to
        # require_association when using single-table inheritance.
        def const_missing(const_name, nesting = nil)
          klass_name = name.presence || "Object"

          if !nesting
            # We'll assume that the nesting of Foo::Bar is ["Foo::Bar", "Foo"]
            # even though it might not be, such as in the case of
            # class Foo::Bar; Baz; end
            nesting = []
            klass_name.to_s.scan(/::|$/) { nesting.unshift $` }
          end

          # If there are multiple levels of nesting to search under, the top
          # level is the one we want to report as the lookup fail.
          error = nil
          nesting.each do |namespace|
            begin
              return Dependencies.load_missing_constant Inflector.constantize(namespace), const_name
            rescue NoMethodError then raise
            rescue NameError => e
              error ||= e
            end
          end

          # Raise the first error for this set. If this const_missing came from an
          # earlier const_missing, this will result in the real error bubbling
          # all the way up
          raise error
        end

        def unloadable(const_desc = self)
          super(const_desc)
        end
      end

      module Exception # :nodoc:
        def blame_file!(file)
          (@blamed_files ||= []).unshift file
        end

        def blamed_files
          @blamed_files ||= []
        end

        def describe_blame
          return nil if blamed_files.empty?
          "This error occurred while loading the following files:\n   #{blamed_files.join "\n   "}"
        end

        def copy_blame!(exc)
          @blamed_files = exc.blamed_files.clone
          self
        end
      end
    end

    extend self
    include Tools

    # Should we turn on Ruby warnings on the first load of dependent files?
    mattr_accessor :warnings_on_first_load
    self.warnings_on_first_load = false

    # All files ever loaded.
    mattr_accessor :history
    self.history = Set.new

    # All files currently loaded.
    mattr_accessor :loaded
    self.loaded = Set.new

    # Should we load files or require them?
    mattr_accessor :mechanism
    self.mechanism = ENV['NO_RELOAD'] ? :require : :load

    # An array of qualified constant names that have been loaded. Adding a name to
    # this array will cause it to be unloaded the next time Dependencies are cleared.
    mattr_accessor :autoloaded_constants
    self.autoloaded_constants = []

    # The set of directories from which we may automatically load files. Files
    # under these directories will be reloaded on each request in development mode,
    # unless the directory also appears in autoload_once_paths.
    mattr_accessor :autoload_paths
    self.autoload_paths = []

    # The set of directories from which automatically loaded constants are loaded
    # only once. All directories in this set must also be present in +autoload_paths+.
    mattr_accessor :autoload_once_paths
    self.autoload_once_paths = []

    # An array of constant names that need to be unloaded on every request. Used
    # to allow arbitrary constants to be marked for unloading.
    mattr_accessor :explicitly_unloadable_constants
    self.explicitly_unloadable_constants = []

    # The logger is used for generating information on the action run-time (including benchmarking) if available.
    # Can be set to nil for no logging. Compatible with both Ruby's own Logger and Log4r loggers.
    mattr_accessor :logger

    # Set to true to enable logging of const_missing and file loads
    mattr_accessor :log_activity
    self.log_activity = false

    mattr_accessor :world_reload_count
    self.world_reload_count = 0

    mattr_accessor :default_strategy
    self.default_strategy = :world

    # An internal stack used to record which constants are loaded by any block.
    mattr_accessor :constant_watch_stack
    self.constant_watch_stack = WatchStack.new

    mattr_accessor :dependencies
    self.dependencies = Hash.new { |h,k| h[k] = Set.new }

    def hook!
      Object.send(:include, Hooks::Object)
      Module.send(:include, Hooks::Module)
      Exception.send(:include, Hooks::Exception)
      true
    end

    def unhook!
      Hooks::Object.exclude_from(Object)
      Hooks::Module.exclude_from(Module)
      true
    end

    def autoloaded?(desc)
      return false if desc.is_a?(Module) and desc.anonymous?
      Constant[desc].autoloaded?
    end

    # Remove the constants that have been autoloaded, and those that have been
    # marked for unloading.
    def remove_unloadable_constants!
      unloadable_constants.each { |const| Constant[const].remove }
      autoloaded_constants.clear
    end

    def unloadable_constants
      autoloaded_constants + explicitly_unloadable_constants
    end

    def remove_constant(desc)
      Constant[desc].remove
    end

    def clear
      log_call
      loaded.clear
      remove_unloadable_constants!
    end

    def ref(desc)
      Constant[desc]
    end

    def constantize(name)
      Constant[name].constant
    end

    def load_missing_constant(from_mod, const_name)
      Constant[from_mod].load_constant(const_name)
    end

    # Run the provided block and detect the new constants that were loaded during
    # its execution. Constants may only be regarded as 'new' once -- so if the
    # block calls +new_constants_in+ again, then the constants defined within the
    # inner call will not be reported in this one.
    #
    # If the provided block does not run to completion, and instead raises an
    # exception, any new constants are regarded as being only partially defined
    # and will be removed immediately.
    def new_constants_in(*descs)
      log_call(*descs)
      watch_frames = constant_watch_stack.add_modules(descs)

      aborting = true
      begin
        yield # Now yield to the code that is to define new constants.
        aborting = false
      ensure
        new_constants = constant_watch_stack.new_constants_for(watch_frames)

        log "New constants: #{new_constants * ', '}"
        return new_constants unless aborting

        log "Error during loading, removing partially loaded constants "
        new_constants.each {|c| remove_constant(c) }.clear
      end

      return []
    ensure
      # Remove the stack frames that we added.
      watch_frames.each {|f| constant_watch_stack.delete(f) } if watch_frames.present?
    end

    # Load the file at the provided path. +const_paths+ is a set of qualified
    # constant names. When loading the file, Dependencies will watch for the
    # addition of these constants. Each that is defined will be marked as
    # autoloaded, and will be removed when Dependencies.clear is next called.
    #
    # If the second parameter is left off, then Dependencies will construct a set
    # of names that the file at +path+ may define. See
    # +loadable_constants_for_path+ for more details.
    def load_file(path, const_paths = loadable_constants_for_path(path))
      log_call path, const_paths
      const_paths = [*const_paths].compact
      parent_paths = const_paths.collect { |const_path| /(.*)::[^:]+\Z/ =~ const_path ? $1 : :Object }

      result = nil
      newly_defined_paths = new_constants_in(*parent_paths) do
        result = Kernel.load path
      end

      autoloaded_constants.concat newly_defined_paths unless load_once_path?(path)
      autoloaded_constants.uniq!
      log "loading #{path} defined #{newly_defined_paths * ', '}" unless newly_defined_paths.empty?
      return result
    end

    def depend_on(file_name, swallow_load_errors = false, message = "No such file to load -- %s.rb", from = nil)
      from ||= File.expand_path(trace.first[/^[^:]+/])
      file_name = search_for_file(file_name) || file_name
      dependencies[file_name] << from
      require_or_load(file_name)
    rescue LoadError => load_error
      unless swallow_load_errors
        if file_name = load_error.message[/ -- (.*?)(\.rb)?$/, 1]
          raise LoadError.new(message % file_name).copy_blame!(load_error)
        end
        raise
      end
    end

    def require_or_load(file_name, const_path = nil)
      log_call file_name, const_path
      file_name = $1 if file_name =~ /^(.*)\.rb$/
      expanded = File.expand_path(file_name)
      return if loaded?(expanded)

      # Record that we've seen this file *before* loading it to avoid an
      # infinite loop with mutual dependencies.
      Dependencies.loaded << expanded

      begin
        if load?
          log "loading #{file_name}"

          # Enable warnings iff this file has not been loaded before and
          # warnings_on_first_load is set.
          load_args = ["#{file_name}.rb"]
          load_args << const_path unless const_path.nil?

          if !warnings_on_first_load or history.include?(expanded)
            result = load_file(*load_args)
          else
            enable_warnings { result = load_file(*load_args) }
          end
        else
          log "requiring #{file_name}"
          result = require file_name
        end
      rescue Exception
        loaded.delete expanded
        raise
      end

      dependencies[expanded].each do |dep|
        require_or_load dep
      end

      # Record history *after* loading so first load gets warnings.
      history << expanded
      return result
    end

    #Deprecation.deprecate_methods self, :autoloaded?, :remove_constant, :ref
    hook!
  end
end
