require 'set'
require 'active_support/core_ext/module/anonymous'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/reachable'
require 'active_support/core_ext/module/introspection'
require 'active_support/deprecation'

module ActiveSupport # :nodoc:
  module Dependencies # :nodoc:
    extend self

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

    def hook!
      Object.send(:include, Loadable)
    end

    def unhook!
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

      attr_reader :constant, :name
      delegate :anonymous?, :reachable?, :to => :constant
      delegate :autoloaded_constants, :to => Dependencies

      def initialize(name, constant)
        @name, @constant      = name, constant
        @associated_constants = Set[self]
        @associated_files     = Set.new
      end

      def associated_files(transitive = true)
        return @associated_files unless transitive
        associated_constants.inject(Set.new) { |a,v| a.merge v.associated_files(false) }
      end

      def associated_constants(transitive = true, bucket = Set.new)
        update_const
        return [] unless unloadable?
        associated = @associated_constants + constant.ancestors + constant.singleton_class.ancestors
        return associated unless transitive
        bucket << self
        associated.each do |c|
          c.associated_constants(true, bucket) unless bucket.include? c
        end
        bucket
      end

      def update_const
        @constant = qualified_const if qualified_const_defined?
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

      def qualified_const
        @names ||= name.split("::")
        @names.inject(Object) do |mod, name|
          return unless Dependencies.local_const_defined?(mod, name)
          mod.const_get(name)
        end
      end

      def autoloaded?
        update_const
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
        deactivate
        constant.parent.const_set const_set.base_name, constant
      end

      def deactivate
        return false unless qualified_const_defined?
        constant.parent.send(:remove_const, constant.base_name)
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
