require 'set'
require 'active_support/inflector'
require 'active_support/deprecation'

module ActiveSupport # :nodoc:
  # Documentation goes here.
  module Dependencies
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

      def trace
        caller.reject {|l| l =~ %r{#{Regexp.escape(__FILE__)}} }
      end

      def name_error(name)
        NameError.new("uninitialized constant #{name}").tap do |name_error|
          name_error.set_backtrace(trace)
        end
      end

      def logger
        Dependencies.logger
      end

      def log_activity?
        Dependencies.log_activity
      end

      def autoloaded_constants
        Dependencies.autoloaded_constants
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
        unless @constant = qualified_const
          @parent.load_constant(local_name)
          @constant = qualified_const
        end
      end

      def qualified_const_defined?
        !!qualified_const
      end

      def qualified_const
        @names ||= name.split("::")
        @names.inject(Object) do |mod, name|
          return unless local_const_defined?(mod, name)
          mod.const_get(name)
        end
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

      def load_constant(const_name)
        log_call self, const_name
        complete_name = object? ? const_name.to_s : "#{name}::#{const_name}"
        if Constant.available? complete_name
          Constant[complete_name].reload
        else
          active!
          file_path = search_for_file(complete_name.underscore)
          if file_path and not loaded?(file_path)
            require_or_load file_path
            raise LoadError, "Expected #{file_path} to define #{qualified_name}" unless local_const_defined?(const_name)
            Constant[]
          else
            raise name_error(complete_name)
          end
        end
      end
    end

    module Hooks
      module Object
        def self.exclude_from(base)
          #base.class_eval { define_method(:load, Kernel.instance_method(:load)) }
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
    end

    extend self
    include Tools

    def hook!
      Object.send(:include, Hooks::Object)
      Module.send(:include, Hooks::Module)
      true
    end

    def unhook!
      Hooks::Object.exclude_from(Object)
      Hooks::Module.exclude_from(Module)
      true
    end

    def autoloaded?(desc)
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

    def load_missing_constant(from_mod, const_name)
      Constant[from_mod].load_constant(const_name)
    end

    #Deprecation.deprecate_methods self, :autoloaded?, :remove_constant, :ref
    hook!
  end
end
