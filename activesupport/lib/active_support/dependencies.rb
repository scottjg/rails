require 'set'
require 'active_support/core_ext/module/anonymous'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/reachable'
require 'active_support/core_ext/module/introspection'

module ActiveSupport # :nodoc:
  module Dependencies # :nodoc:
    extend self

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
        name.sub! /^::/, ''
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

      attr_reader :constant
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
        @constant = c if c = qualified_const
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
        names.inject(Object) do |mod, name|
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
  end
end
