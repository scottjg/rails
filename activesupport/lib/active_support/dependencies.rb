require 'set'
require 'active_support/core_ext/module/anonymous'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/reachable'
require 'active_support/core_ext/module/introspection'
require 'active_support/deprecation'

module ActiveSupport # :nodoc:
  module Dependencies # :nodoc:
    extend self

    class WatchStack < Array
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
          mod = Inflector.constantize(mod_name) if Dependencies.qualified_const_defined?(mod_name)
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
          name = Dependencies.to_constant_name(desc)
          consts = Dependencies.qualified_const_defined?(name) ?
          Inflector.constantize(name).local_constant_names : []
          [name, consts]
        end
        concat(list)
        list
      end

      def lock
        @mutex.synchronize { yield self }
      end
    end

    # Should we turn on Ruby warnings on the first load of dependent files?
    mattr_accessor :warnings_on_first_load
    self.warnings_on_first_load = false

    # An array of qualified constant names that have been loaded. Adding a name to
    # this array will cause it to be unloaded the next time Dependencies are cleared.
    mattr_accessor :autoloaded_constants
    self.autoloaded_constants = []

    # The set of directories from which we may automatically load files. Files
    # under these directories will be reloaded on each request in development mode,
    # unless the directory also appears in autoload_once_paths.
    mattr_accessor :autoload_paths
    self.autoload_paths = []

    # Should we load files or require them?
    mattr_accessor :mechanism
    self.mechanism = ENV['NO_RELOAD'] ? :require : :load

    # An array of constant names that need to be unloaded on every request. Used
    # to allow arbitrary constants to be marked for unloading.
    mattr_accessor :explicitly_unloadable_constants
    self.explicitly_unloadable_constants = []

    # All files currently loaded.
    mattr_accessor :loaded
    self.loaded = Set.new

    # All files ever loaded.
    mattr_accessor :history
    self.history = Set.new

    # The set of directories from which automatically loaded constants are loaded
    # only once. All directories in this set must also be present in +autoload_paths+.
    mattr_accessor :autoload_once_paths
    self.autoload_once_paths = []

    # An internal stack used to record which constants are loaded by any block.
    mattr_accessor :constant_watch_stack
    self.constant_watch_stack = WatchStack.new

    mattr_accessor :world_reload_count
    self.world_reload_count = 0

    mattr_accessor :default_strategy
    self.default_strategy = :world

    def hook!
      Object.send(:include, Loadable)
    end

    def unhook!
    end

    module Strategies
      module World
        def mark
          return false if reload?
          # avoid looping through all constants
          Dependencies.world_reload_count += 1
          mark!
        end
      end

      module Associated
        include World

        def mark
          return false if reload?
          associated_constants.each(&:mark)
          mark!
        end
      end

      module MonkeyPatch
        def mark
          mark!
        end
      end
    end

    # Object includes this module
    module Loadable #:nodoc:
      def unloadable
      end

      def require_or_load(file_name)
      end

      def require_dependency(file_name, message = "No such file to load -- %s")
        unless file_name.is_a?(String)
          raise ArgumentError, "the file name must be a String -- you passed #{file_name.inspect}"
        end
      end

      def require_association(file_name)
      end
    end

    # Note that a Constant will also store constants that have been removed,
    # which allows bringing a constant back to live without loading the source file.
    class Constant # :nodoc:
      extend Enumerable

      def self.map
        @map ||= {}
      end

      def self.all
        map.values
      end

      def self.each(&block)
        all.each(&block)
      end

      def self.new(name, constant = nil)
        name, constant = name.name, name if constant.nil? and name.respond_to? :name
        name = Dependencies.to_constant_name name
        constant = Inflector.constantize(name) unless constant
        return super if name.blank?
        if self === constant
          map[name] = constant
        else
          map[name] ||= super
        end
      end

      class << self
        alias [] new
        alias []= new
      end

      attr_reader :constant, :name, :strategy
      delegate :anonymous?, :reachable?, :const_set, :const_get, :to => :constant
      delegate :autoloaded_constants, :to => Dependencies

      def initialize(name, constant)
        @name, @constant      = name, constant
        @associated_constants = Set[self]
        @associated_files     = Set.new
        self.strategy         = Dependencies.default_strategy
      end

      def class?
        Class === constant
      end

      def module?(include_classes = false)
        Module === constant and (include_classes or !class?)
      end

      def associated_files(transitive = true)
        return @associated_files unless transitive
        associated_constants.inject(Set.new) { |a,v| a.merge v.associated_files(false) }
      end

      def associated_constants(transitive = true, bucket = Set.new)
        return [] unless unloadable?
        associated = @associated_constants
        associated_constants += constant.ancestors + constant.singleton_class.ancestors if module?(true)
        return associated unless transitive
        bucket << self
        associated.each do |c|
          c.associated_constants(true, bucket) unless bucket.include? c
        end
        bucket
      end

      def associate_with_constant(other)
        @associated_constants << Constant[other]
      end

      def associate_with_file(file)
        @associated_files << file
      end

      def qualified_const_defined?
        !!qualified_const
      end

      alias active? qualified_const_defined?

      def qualified_const
        @names ||= name.split("::")
        @constant = @names.inject(Object) do |mod, name|
          return unless Dependencies.local_const_defined?(mod, name)
          mod.const_get(name)
        end
      end

      def parent
        Constant[constant.parent]
      end

      def remove_const(desc)
        constant.send(:remove_const, desc)
      end

      def autoloaded?
        !anonymous? and qualified_const_defined? and autoloaded_constants.include?(name)
      end

      def unload?
        autoloaded? or explicitly_unloadable?
      end

      def explicitly_unloadable?
      end

      def reload?
      end

      def activate
        return false if active?
        parent.activate
        parent.const_set const_set.base_name, constant
      end

      def deactivate
        return false unless qualified_const_defined?
        parent.remove_const(constant.base_name)
      end

      def unload
        unload! if unload?
      end

      def load
        reload? ? load! : activate
      end

      def unload!
      end

      def load!
      end

      def strategy=(value)
        value = Strategies.const_get(Inflector.camelize(value.to_s)) unless Module === value
        extend value
        @strategy = value
      end
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

    def schedule_reload
    end

    alias clear schedule_reload

    def autoloaded?(desc)
      Constant[desc].autoloaded?
    end

    def remove_constant(desc)
      Constant[desc].deactivate
    end

    def ref(desc)
      Constant[desc]
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

    # Run the provided block and detect the new constants that were loaded during
    # its execution. Constants may only be regarded as 'new' once -- so if the
    # block calls +new_constants_in+ again, then the constants defined within the
    # inner call will not be reported in this one.
    #
    # If the provided block does not run to completion, and instead raises an
    # exception, any new constants are regarded as being only partially defined
    # and will be removed immediately.
    def new_constants_in(*descs)
      #log_call(*descs)
      watch_frames = constant_watch_stack.add_modules(descs)

      aborting = true
      begin
        yield # Now yield to the code that is to define new constants.
        aborting = false
      ensure
        new_constants = constant_watch_stack.new_constants_for(watch_frames)

        #log "New constants: #{new_constants * ', '}"
        return new_constants unless aborting

        #log "Error during loading, removing partially loaded constants "
        new_constants.each {|c| remove_constant(c) }.clear
      end

      return []
    ensure
      # Remove the stack frames that we added.
      watch_frames.each {|f| constant_watch_stack.delete(f) } if watch_frames.present?
    end

    # Search for a file in autoload_paths matching the provided suffix.
    def search_for_file(path_suffix)
      path_suffix = path_suffix.sub(/(\.rb)?$/, ".rb")

      autoload_paths.each do |root|
        path = File.join(root, path_suffix)
        return path if File.file? path
      end
      nil # Gee, I sure wish we had first_match ;-)
    end

    # Convert the provided const desc to a qualified constant name (as a string).
    # A module, class, symbol, or string may be provided.
    def to_constant_name(desc) #:nodoc:
      name = case desc
      when String then desc.sub(/^::/, '')
      when Symbol then desc.to_s
      when Module
        desc.name.presence ||
        raise(ArgumentError, "Anonymous modules have no name to be referenced by")
      else raise TypeError, "Not a valid constant descriptor: #{desc.inspect}"
      end
    end

    # Return the constant path for the provided parent and constant name.
    def qualified_name_for(mod, name)
      mod_name = to_constant_name mod
      mod_name == "Object" ? name.to_s : "#{mod_name}::#{name}"
    end

    def qualified_const_defined?(desc)
      Constant[desc].qualified_const_defined?
    end

    Deprecation.deprecate_methods self, :autoloaded?, :clear, :remove_constant, :ref, :qualified_const_defined?
    hook!
  end
end
