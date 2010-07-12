require 'set'
require 'active_support/inflector'

module ActiveSupport # :nodoc:
  # Documentation goes here.
  module Dependencies
    # The logger is used for generating information on the action run-time (including benchmarking) if available.
    # Can be set to nil for no logging. Compatible with both Ruby's own Logger and Log4r loggers.
    mattr_accessor :logger

    # Set to true to enable logging of const_missing and file loads
    mattr_accessor :log_activity
    self.log_activity = false

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

      def logger
        Dependencies.logger
      end

      def log_activity?
        Dependencies.log_activity
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
          parent_name, @local_name = $`, $1
        else
          parent_name, @local_name = :Object, name
        end
        @parent = Constant[parent]
        unless @constant = qualified_const
          @parent.load_constant(local_name)
        end
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

      def active?
        qualified_const == constant
      end

      def load_constant(local_name)
        complete_name = "#{name}::#{local_name}"
        if Constant.available? complete_name
          Constant[complete_name].reload
        else
          raise NotImplementedError
        end
      end
    end

    extend self
    include Tools

    def load_missing_constant(from_mod, const_name)
      Constant[from_mod].load_constant(const_name)
    end
  end
end
