require 'set'

module ActiveSupport # :nodoc:
  module Dependencies # :nodoc:
    extend self

    class Constant
      extend Enumerable

      def self.map
        @map ||= {}
      end

      def self.all
        map.each
      end

      def self.each
        # avoid creating a Proc for performance
        return all.each unless block_given?
        all.each { |c| yield(c) }
      end

      def self.new(name, constant = nil)
        name, constant = name.name, name if constant.nil? and name.respond_to? :name
        constant = Inflector.constantize(name) unless constant
        return super if name.blank? # anonymous module
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

      def initialize(name, constant)
        @name, @constant      = name, constant
        @associated_constants = Set[self, Constant[constant.parent]]
        @associated_files     = Set.new
      end

      def associated_files(transitive = true)
        return @associated_files unless transitive
        associated_constants.inject(Set.new) { |a,v| a.merge v.associated_files(false) }
      end

      def associated_constants(transitive = true, bucket = Set.new)
        return @associated_constants unless transitive
        bucket << self
        @associated_constants.each do |c|
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
