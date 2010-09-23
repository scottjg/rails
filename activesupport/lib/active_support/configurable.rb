require 'active_support/concern'
require 'active_support/ordered_options'
require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/module/delegation'

module ActiveSupport
  # Configurable provides a <tt>config</tt> method to store and retrieve
  # configuration options as an <tt>OrderedHash</tt>.
  module Configurable
    extend ActiveSupport::Concern

    class Options < ActiveSupport::InheritableOptions
      def crystalize!
        self.class.crystalize!(keys.reject {|key| respond_to?(key)})
      end

      # compiles reader methods so we don't have to go through method_missing
      def self.crystalize!(keys)
        keys.each do |key|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{key}; self[#{key.inspect}]; end
          RUBY
        end
      end
    end
    
    included do
      _setup_configuration_class
    end

    module ClassMethods
      def config
        @_config ||= superclass.respond_to?(:config) ? superclass.config.inheritable_copy : self::CONF_OPTIONS_CLASS.new
      end

      def configure
        yield config
      end

      def config_accessor(*names)
        names.each do |name|
          code, line = <<-RUBY, __LINE__ + 1
            def #{name}; config.#{name}; end
            def #{name}=(value); config.#{name} = value; end
          RUBY

          singleton_class.class_eval code, __FILE__, line
          class_eval code, __FILE__, line
        end
      end

      def _setup_configuration_class
        const_set(:CONF_OPTIONS_CLASS, Class.new(defined?(CONF_OPTIONS_CLASS) ? CONF_OPTIONS_CLASS : Options))
      end
    end

    # Reads and writes attributes from a configuration <tt>OrderedHash</tt>.
    # 
    #   require 'active_support/configurable'      
    #  
    #   class User
    #     include ActiveSupport::Configurable
    #   end 
    #
    #   user = User.new
    # 
    #   user.config.allowed_access = true
    #   user.config.level = 1
    #
    #   user.config.allowed_access # => true
    #   user.config.level          # => 1
    # 
    def config
      @_config ||= self.class.config.inheritable_copy
    end
  end
end

