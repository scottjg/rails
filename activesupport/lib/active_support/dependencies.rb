require 'set'
require 'active_support/core_ext/module/anonymous'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/reachable'

module ActiveSupport # :nodoc:
  module Dependencies # :nodoc:
    extend self

    # Note that a Constant will also store constants that have been removed,
    # which allows bringing a constant back to live without loading the source file.
    class Constant
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
        return [] unless unloadable?
        associated = @associated_constants + constant.ancestors + constant.singleton_class.ancestors
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
    end

    def schedule_reload
    end
  end
end
