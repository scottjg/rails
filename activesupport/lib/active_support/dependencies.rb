require 'set'
require 'active_support/core_ext/module/anonymous'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/reachable'
require 'active_support/core_ext/module/introspection'
require 'active_support/deprecation'

module ActiveSupport # :nodoc:
  module Dependencies # :nodoc:
    extend self

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
        constant = Inflector.constantize(name) unless constant
        return super if name.blank?
        name.sub! /^((::)?Object)?::/, ''
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
        raise NotImplementedError
      end

      def reload?
        raise NotImplementedError
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
        raise NotImplementedError
      end

      def load!
        raise NotImplementedError
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

    Deprecation.deprecate_methods self, :autoloaded?, :clear
  end
end
