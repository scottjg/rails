require 'thread'
require 'active_support/dependencies/hard_reloader'

module ActiveSupport # :nodoc:
  module Dependencies # :nodoc:
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

    mattr_accessor :mutex
    self.mutex = Mutex.new

    mattr_accessor :default_strategy
    self.default_strategy = HardReloader

    def self.lock
      mutex.synchronize { yield }
    end

    def self.method_missing(name, *args, &block)
      lock { self.strategy = default_strategy unless set_strategy? }
      return send(name, *args, &block) if respond_to? name
      super
    end

    def self.set_strategy?
      !!@strategy
    end

    def self.strategy=(value)
      fail 'strategy already set' if set_strategy?
      include value
      extend self
      @strategy = value
    end
  end
end
