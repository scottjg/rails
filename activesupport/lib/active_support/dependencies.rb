require 'set'
require 'thread'
require 'active_support/inflector'
require 'active_support/deprecation'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/introspection'
require 'active_support/core_ext/module/anonymous'
require 'active_support/core_ext/kernel/singleton_class'

module ActiveSupport
  # Takes care of loading and reloading your classes and modules from a given set
  # of paths. Dependencies will be set up correctly when using Rails.
  #
  # Example usage:
  #   require 'active_support/dependencies'
  #   
  #   # search for files in path
  #   ActiveSupport::Dependencies.autoload_paths = ['lib']
  #   ActiveSupport::Dependencies.mechanism = :load # use load - allows reloading code
  #   
  #   # Will load ExampleClass from lib/example_class.rb
  #   ExampleClass.do_something
  #   
  #   # Will trigger a reload if a file has been changed
  #   ActiveSupport::Dependencies.clear
  #   
  #   ExampleClass.do_something_else
  module Dependencies
    # Will be included into Dependencies, WatchStack and Constant
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

      # Convert a provided strategy desc into a strategy mixin:
      #   to_strategy(MyStrategy) # => MyStrategy
      #   to_strategy(:world)     # => ActiveSupport::Strategies::World
      def to_strategy(desc) # :nodoc:
        return desc if Module === desc
        Strategies.const_get desc.to_s.camelcase
      end

      # Returns true if a qualified constant matching name is defined.
      # See qualified_const.
      def qualified_const_defined?(name)
        !!qualified_const(name)
      end

      # Returns the qualified constant for a given const desc.
      #
      # Example:
      #   module Example
      #     include ActiveSupport::Dependencies::Tools
      #     module Foo
      #     end
      #     
      #     foo = Foo
      #     qualified_const(foo) # => Example::Foo
      #     
      #     remove_const(:Foo)
      #     qualified_const(foo) # => nil
      #     
      #     Foo = Array
      #     qualified_const(foo) # => Array
      #   end
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

      # The file a method is called on.
      def calling_from # :nodoc:
        File.expand_path(trace.first[/^[^:]+/])
      end

      # Cleaned backtrace.
      def trace # :nodoc:
        caller.reject {|l| l =~ %r{#{Regexp.escape(__FILE__)}} }
      end

      # Generates a NameError for +name+ with cleaned +trace+.
      def name_error(name) # :nodoc:
        NameError.new("uninitialized constant #{name}").tap do |name_error|
          name_error.set_backtrace(trace)
        end
      end

      # Whether to use load or require.
      def load?
        Dependencies.mechanism == :load
      end

      # Shorthand for Dependencies.logger
      def logger # :nodoc:
        Dependencies.logger
      end

      # Shorthand for Dependencies.log_activity
      def log_activity? # :nodoc:
        Dependencies.log_activity
      end

      # Shorthand for Dependencies.autoloaded_constants
      def autoloaded_constants # :nodoc:
        Dependencies.autoloaded_constants
      end

      # Checks whether given +path+ should only be autoloaded once.
      def load_once_path?(path)
        Dependencies.autoload_once_paths.any? { |base| path.starts_with? base }
      end

      # Shorthand for Dependencies.require_or_load
      def require_or_load(file_name, const_path = nil) # :nodoc:
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

      # Whether or not +file+ has been loaded by Dependencies since the last +clear+.
      def loaded?(file)
        Dependencies.loaded.include? File.expand_path(file)
      end

      # Return the constant path for the provided parent and constant name.
      def qualified_name_for(mod, name)
        mod_name = to_constant_name mod
        mod_name == "Object" ? name.to_s : "#{mod_name}::#{name}"
      end

      protected

      def log_call(*args) # :nodoc:
        if logger && log_activity?
          arg_str = args.collect { |arg| arg.inspect } * ', '
          /in `([a-z_\?\!]+)'/ =~ caller(1).first
          selector = $1 || '<unknown>'
          log "called #{selector}(#{arg_str})"
        end
      end

      def log(msg) # :nodoc:
        if logger && log_activity?
          logger.debug "Dependencies: #{msg}"
        end
      end
    end

    # A WatchStack is used to track constants added to object space.
    class WatchStack < Array
      include Tools

      def initialize
        @mutex = Mutex.new
      end

      def self.locked(*methods) # :nodoc:
        methods.each { |m| class_eval "def #{m}(*) lock { super } end", __FILE__, __LINE__ }
      end

      locked :concat, :each, :delete_if, :<<

      # Given a list of frames (parent module and all constants defined in it).
      # Add new constants to the frames (thus not treating those as new the next time)
      # and return an array of those new constants.
      def new_constants_for(frames)
        constants = []
        frames.each do |mod_name, prior_constants|
          mod = Inflector.constantize(mod_name) if qualified_const_defined?(mod_name)
          next unless mod.is_a?(Module)

          new_constants = mod.local_constant_names - prior_constants

          # If we are checking for constants under, say, :Object, nested under something
          # else that is checking for constants also under :Object, make sure the
          # parent knows that we have found, and taken care of, the constant.
          #
          # In particular, this means that since Kernel.require discards the constants
          # it finds, parents will be notified that about those constants, and not
          # consider them "new". As a result, they will not be added to the
          # autoloaded_constants list.
          each do |key, value|
            value.concat(new_constants) if key == mod_name
          end

          new_constants.each do |suffix|
            name = mod_name == "Object" ? suffix : [mod_name, suffix].join("::")
            constants << name
            # Update reference, avoids uneccesary "already activated" errors.
            Constant[name].update
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

      def lock(&block) # :nodoc:
        @mutex.synchronize(&block)
      end
    end

    module Strategies # :nodoc:
      # World reloading strategy. Reload all reloadable constants if a single file changed.
      # Default strategy.
      #
      # Constants will be removed and re-defined on reload.
      #
      # Keep in mind:
      # Errors will occure if references to old constants or instances are
      # kept by parts of the object space that are not reloaded.
      module World
        def mark! # :nodoc:
          Dependencies.world_reload_count = Dependencies.reload_count
        end
      end

      # Sloppy reloading strategy. Will only reload associated constants.
      #
      #   # foo.rb
      #   class Foo
      #   end
      #
      #   # bar.rb
      #   class Bar
      #     associate_with Foo
      #   end
      #
      #   # blah.rb
      #   class Blah
      #   end
      #
      # In the above example changes to foo.rb or bar.rb will only reload Foo and Bar.
      # Different events will automatically set associations (like include, extend, subclassing,
      # require_dependency, etc).
      #
      # Constants will be removed and re-defined on reload.
      #
      # Still highly experimental.
      #
      # Keep in mind:
      # Errors will occure if references to old constants or instances are
      # kept by parts of the object space that are not reloaded.
      module Sloppy
        def mark!
          list = associations
          if constant
            list.push(*constant.ancestors)
            list.push(*constant.singleton_class.ancestors)
          end
          list.each { |c| Constant[c].mark if Constant.available?(c) }
        end
      end

      # Monkey patching reloading strategy. Will only reload classes and modules
      # defined in files that changed.
      #
      # Instead of removing a class or module before reloading it, it is simply kept
      # and patches itself on a reload. When using this strategy, make sure that the
      # code in your files may be executed twice.
      #
      # It has the advantage of not invalidating existing instances and references.
      #
      # Still highly experimental.
      module MonkeyPatch
        def invalidate_remains
        end

        def prepare
          activate
        end
      end
    end

    # Wrapper class for classes and modules.
    # It is not intended to be used directly.
    class Constant
      extend Enumerable
      include Tools

      # Constant name - wrapper mapping
      mattr_accessor :map
      self.map ||= {}

      # Checks whether a constant wrapper is already defined.
      # Example:
      #   class Foo; end
      #   ActiveSupport::Dependencies::Constant.available? "Bar" # => false
      #   ActiveSupport::Dependencies::Constant.available? "Foo" # => true
      #
      #   const = ActiveSupport::Dependencies::Constant["Bar"]
      #   ActiveSupport::Dependencies::Constant.available? "Bar" # => true
      def self.available?(name)
        name = to_constant_name(name)
        map.include?(name) or qualified_const_defined?(name)
      end

      # Creates new wrapper.
      # Argument will be converted via +to_constant_name+.
      # If the argument is a Constant, it will be returned instead.
      def self.new(name)
        return name if Constant === name
        name = to_constant_name(name)
        map[name] ||= super
      end

      class << self
        alias [] new
      end

      attr_accessor :name, :constant, :parent, :local_name, :last_reload, :associations

      def initialize(name) # :nodoc:
        @file         = nil
        @marked       = false
        @unloadable   = nil
        @name         = name
        @last_reload  = 0
        @associations = Set.new
        if name =~ /::([^:]+)\Z/
          @parent, @local_name = Constant[$`], $1
        elsif object?
          @parent, @local_name = self, 'Object'
        else
          @parent, @local_name = Constant[Object], name
        end
        self.strategy = Dependencies.default_strategy
        update
      end

      # Strategy used for reloading the constant.
      #
      # Example:
      #   ActiveSupport::Dependencies::Constant["Foo"].strategy = :monkey_patch
      #   ActiveSupport::Dependencies::Constant["Bar"].strategy = MyStrategy
      def strategy=(mod)
        extend to_strategy(mod)
        mod
      end

      # Associates the constant with another constant.
      # Used by the sloppy reloader.
      def associate_with(const)
        associations << Constant[const]
      end

      # Action to be performed before loading the source.
      # Intended to be overwritten by the strategy when necessary.
      def prepare
      end

      # Returns the qualified name for
      #   ActiveSupport::Dependencies::Constant["Foo"].qualified_name_for "Bar" # => "Foo::Bar"
      def qualified_name_for(mod, name = nil)
        mod, name = self, mod unless name
        super(mod, name)
      end

      # Whether or not the constant wrapped is defined.
      #   ActiveSupport::Dependencies::Constant["Foo"].qualified_const_defined? # => false
      #   class Foo; end
      #   ActiveSupport::Dependencies::Constant["Foo"].qualified_const_defined? # => true
      def qualified_const_defined?(desc = name)
        super
      end

      def qualified_const(desc = name) # :nodoc:
        super
      end

      # Updates internal constant to match outer constant.
      def update # :nodoc:
        @last_reload = Dependencies.world_reload_count
        if const = qualified_const and const != constant
          invalidate_class_remains(constant)
        end
        @constant = const
      end

      def object? # :nodoc:
        name == 'Object'
      end

      # Whether the current constant is active (it is defined and not an older version).
      def active?
        remove_placeholder
        return false unless const = qualified_const
        const.dependency_placeholder? or constant == const
      end

      # Like +active?+ but instead of returning false it raises and ArgumentError.
      def active!
        unless active?
          raise ArgumentError, "A copy of #{name} has been removed from the module tree but is still active!"
        end
        true
      end

      # Whether or not the constant has been autoloaded (which will cause it to reload).
      def autoloaded?
        qualified_const_defined? and autoloaded_constants.include?(name)
      end

      # Explicitly mark the constant as reloadable (see ActiveSupport::Dependencies::Hooks::Module#unloadable).
      def unloadable!
        return false if @unloadable
        Dependencies.explicitly_unloadable_constants << self
        @unloadable = true
      end

      # Whether or not class is reloadable (explicitly or since it is autoloaded).
      def unloadable?
        return true if @unloadable or autoloaded?
        return false unless @unloadable.nil?
        @unloadable = Dependencies.explicitly_unloadable_constants.any? do |desc|
          Constant[desc] == self
        end
      end

      def file
        @file ||= begin
          if f = search_for_file(name.underscore)
            File.expand_path(f)
          end
        end
      end

      def possible_features
        return [] unless file
        @possible_features ||= begin
          features = [file]
          $:.each do |path|
            path = File.expand_path(path)
            features << file[(path.size+1)..-1] if file.start_with?(path)
          end
          features
        end
      end

      # Removes the constant from object space.
      def remove
        parent.remove_constant(local_name) if qualified_const_defined?
        possible_features.each { |feature| $".delete(feature) }
      end

      # Removes a nested constant from object space.
      def remove_constant(const_name)
        constant.send(:remove_const, const_name) if constant
      end

      # Checks whether a nested constant is defined.
      def local_const_defined?(mod, name = nil)
        mod, name = constant, mod unless name
        super(mod, name) if mod
      end

      # Adds the constant to object space.
      def activate
        parent.update
        parent.constant.const_set(name, constant)
        ActiveSupport::Dependencies.autoloaded_constants << name
        constant
      end

      # Whether or not the constant has been marked for reload.
      def marked?
        return true unless Dependencies.check_mtime
        last_reload < Dependencies.world_reload_count or @marked
      end

      def mark! #:nodoc:
      end

      # Marks the constant for reload.
      def mark
        mark! unless marked?
        @marked = true
      end

      def remove_placeholder
        if constant and constant.dependency_placeholder?
          @constant = nil
          remove
        end
      end

      def invalidate_remains
        return unless Dependencies.invalidate_old
        invalidate_class_remains(constant)
        invalidate_class_remains(qualified_const)
        remove_placeholder
      end

      def invalidate_class_remains(klass)
        return unless Dependencies.invalidate_old and Module === klass # allows passing in nil
        singleton = klass.singleton_class
        klass.methods.each do |method|
          method = method.to_s
          next if method =~ /^__/ or method == 'inspect'
          singleton.send(:undef_method, method)
        end
        const = self
        singleton.send(:define_method, :dependency_placeholder?) { true }
        singleton.send(:define_method, :method_missing) do |*a,&b|
          const.active!
          const.qualified_const.send(*a, &b)
        end
      end

      def load_constant(from_mod, const_name) # :nodoc:
        log_call const_name
        Dependencies.check_updates

        self.constant = from_mod unless active?
        active!

        complete_name = qualified_name_for(const_name)
        if Constant.available? complete_name
          const = Constant[complete_name]
          return const.activate unless const.marked?
          const.invalidate_remains
        end

        path_suffix = complete_name.underscore
        file_path   = search_for_file(path_suffix)

        unless local_const_defined?(const_name)
          Constant[complete_name].prepare if Constant.available? complete_name

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
        end

        Constant[complete_name].update
      end

      def load_parent_constant(const_name, complete_name) # :nodoc:
        parent.load_constant(parent.constant, const_name)
      rescue NameError => e
        raise unless e.missing_name? qualified_name_for(parent, const_name)
        raise name_error(complete_name)
      end

      alias get constant
      #Deprecation.deprecate_methods self, :get
    end

    module Hooks # :nodoc:
      # Module included into Object to enable hooks and public API.
      module Object # :nodoc:
        def self.exclude_from(base) # :nodoc:
          base.class_eval { define_method(:load, Kernel.instance_method(:load)) }
        end

        # Use this method instead of reload or require when loading reloadable code.
        # Otherwise dependencies and new constants will not be tracked and code might not
        # be reloadable.
        def require_dependency(file_name, message = "No such file to load -- %s")
          unless file_name.is_a?(String)
            raise ArgumentError, "the file name must be a String -- you passed #{file_name.inspect}"
          end

          Dependencies.depend_on(file_name, false, message)
        end

        # Like +require_dependency+, but can be called for files that do not exist
        # without raising an error.
        def require_association(file_name)
          Dependencies.associate_with(file_name)
        end

        def load(file, *) # :nodoc:
          load_dependency(file) { super }
        end

        def require(file, *) # :nodoc:
          load_dependency(file) { super }
        end

        def load_dependency(file) # :nodoc:
          if Dependencies.load?
            Dependencies.new_constants_in(:Object) { yield }.presence
          else
            yield
          end
        rescue Exception => exception  # errors from loading file
          exception.blame_file! file
          raise
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

      # Module included into Module to enable hooks and public API.
      module Module # :nodoc:
        def self.append_features(base) # :nodoc:
          base.class_eval do
            # Emulate #exclude via an ivar
            return if defined?(@_const_missing) && @_const_missing
            @_const_missing = instance_method(:const_missing)
            remove_method(:const_missing)
          end
          super
        end

        def self.exclude_from(base) # :nodoc:
          base.class_eval do
            define_method :const_missing, @_const_missing
            @_const_missing = nil
          end
        end

        def dependency_placeholder? # :nodoc:
          false
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

        # Associates the curren module with the given constant.
        # If the second parameter is true (default), the association will be created
        # for both directions.
        #
        # Used by the sloppy reloading strategy.
        def associate_with(const, reverse = true)
          return if anonymous? or const.anonymous?
          Constant[const].associate_with(self) if reverse
          Constant[self].associate_with(const)
        end

        # Mark this module/class as unloadable. Unloadable constants are removed each
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
        def unloadable(const_desc = self)
          super(const_desc)
        end
      end

      # Module included into Exception to enable hooks and internal API.
      module Exception # :nodoc:
        def blame_file!(file) # :nodoc:
          (@blamed_files ||= []).unshift file
        end

        def blamed_files # :nodoc:
          @blamed_files ||= []
        end

        def describe_blame # :nodoc:
          return nil if blamed_files.empty?
          "This error occurred while loading the following files:\n   #{blamed_files.join "\n   "}"
        end

        def copy_blame!(exc) # :nodoc:
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

    # Default reloading strategy to be used.
    mattr_accessor :default_strategy
    self.default_strategy = :world

    # An internal stack used to record which constants are loaded by any block.
    mattr_accessor :constant_watch_stack
    self.constant_watch_stack = WatchStack.new

    # Hash tracking file dependencies (created by require_dependency and require_association).
    mattr_accessor :dependencies
    self.dependencies = Hash.new { |h,k| h[k] = Set.new }

    # Internal counter used to avoid having to mark all constants on world reloading.
    mattr_accessor :world_reload_count
    self.world_reload_count = 0

    # Internal counter increased on every reload.
    mattr_accessor :reload_count
    self.reload_count = 0

    # Flag indicating whether file changes have been checked since the last +clear+.
    mattr_accessor :checked_updates
    self.checked_updates = false

    # Map of last change times for the files loaded.
    mattr_accessor :mtimes
    self.mtimes = {}

    # Used for synchronization.
    mattr_accessor :mutex
    self.mutex = Mutex.new

    # Whether or not to check for file changes and only reload if changes occur.
    mattr_accessor :check_mtime
    self.check_mtime = true

    # Whether or not to invalidate old references
    mattr_accessor :invalidate_old
    self.invalidate_old = true

    # Enables dependency hooks.
    def hook!
      lock do
        Object.send(:include, Hooks::Object)
        Module.send(:include, Hooks::Module)
        Exception.send(:include, Hooks::Exception)
        true
      end
    end

    # Disables dependency hooks.
    def unhook!
      lock do
        Hooks::Object.exclude_from(Object)
        Hooks::Module.exclude_from(Module)
        true
      end
    end

    def lock(&block) # :nodoc:
      mutex.synchronize(&block)
    end

    # See +Constant#autoloaded?+.
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

    # List of all unloadble constants currently active.
    def unloadable_constants
      autoloaded_constants + explicitly_unloadable_constants
    end

    # See +Constant#remove+.
    def remove_constant(desc)
      Constant[desc].remove
    end

    # Checks for file changes.
    def check_updates
      return if checked_updates or !load?
      lock do
        history.each do |file|
          mtime = mtime(file)
          next if mtime and mtime == mtimes[file]
          mtimes[file] = mtime
          loadable_constants_for_path(file).each do |desc|
            Constant[desc].mark! if Constant.available?(desc)
          end
        end
        self.checked_updates = true
      end
    end

    # Time for the last change made on +file+, aware that a file extension might be missing.
    def mtime(file, ext = '.rb')
      return File.mtime(file) if File.file?(file)
      return mtime("#{file}#{ext}", nil) if ext
    end

    # Removes all unloadable constants, increases +reload_count+ and schedules a reload.
    def clear
      log_call
      lock do
        loaded.clear
        self.default_strategy = to_strategy(default_strategy)
        self.reload_count += 1
        remove_unloadable_constants!
        if mtimes.empty?
          history.each do |file|
            mtimes[file] = mtime(file)
          end
        end
        self.checked_updates = false
      end
    end

    # Preforms a +clear+ and removes all meta data (tracked files, last changes, constant map).
    def clear!
      log_call
      [self, explicitly_unloadable_constants, mtimes, history, Constant.map, constant_watch_stack].each do |list|
        list.clear
      end
    end

    def ref(desc) # :nodoc:
      Constant[desc]
    end

    def constantize(name) # :nodoc:
      Constant[name].constant
    end

    def load_missing_constant(from_mod, const_name) # :nodoc:
      Constant[from_mod].load_constant(from_mod, const_name)
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

    # See +require_dependency+.
    def depend_on(file_name, swallow_load_errors = false, message = "No such file to load -- %s.rb", from = nil)
      from ||= calling_from
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

    # See +require_association+.
    def associate_with(file_name)
      depend_on(file_name, true)
    end

    # +require+s or +load+s a file, depending on the chose mechanism.
    # Starts tracking loaded files for changes and makes sure files
    # are not loaded twice between +clear+s.
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

class Class # :nodoc:
  alias inherited_without_dependencies inherited
  def inherited(klass) # :nodoc:
    klass.associate_with(self, false)
    inherited_without_dependencies(klass)
  end
end

class Module # :nodoc:
  alias append_features_without_dependencies append_features
  def append_features(mod) # :nodoc:
    associate_with(mod)
    append_features_without_dependencies(mod)
  end

  alias extend_object_without_dependencies extend_object
  def extend_object(mod) # :nodoc:
    associate_with(mod) if Module === mod
    extend_object_without_dependencies(mod)
  end
end

