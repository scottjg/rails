require 'rubygems'
require 'logger'
require 'set'
require 'pathname'
require 'active_support/core_ext/duplicable'
require 'active_support/core_ext/array'
require 'active_support/core_ext/class/inheritable_attributes'
require 'active_support/core_ext/module/attribute_accessors'

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'railties_path'
require 'rails/version'
require 'rails/plugin/locator'
require 'rails/plugin/loader'
require 'rails/gem_dependency'
require 'rails/rack'
require 'initializer/configuration'

RAILS_ENV = (ENV['RAILS_ENV'] || 'development').dup unless defined?(RAILS_ENV)

module Rails  
  mattr_accessor :started
  class << self
    
    def initialized?
      @initialized || false
    end

    def initialized=(initialized)
      @initialized ||= initialized
    end
    
    # The Configuration instance used to configure the Rails environment
    def configuration
      @configuration
    end

    def configuration=(configuration)
      @configuration = configuration
    end

    def logger
      if defined?(RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      else
        nil
      end
    end

    def backtrace_cleaner
      @@backtrace_cleaner ||= begin
        # Relies on ActiveSupport, so we have to lazy load to postpone definition until AS has been loaded
        require 'rails/backtrace_cleaner'
        Rails::BacktraceCleaner.new
      end
    end

    def root
      @root ||= Pathname.new(RAILS_ROOT) if defined?(RAILS_ROOT)
    end

    def env
      @_env ||= ActiveSupport::StringInquirer.new(RAILS_ENV)
    end

    def cache
      RAILS_CACHE
    end

    def version
      VERSION::STRING
    end

    def public_path
      @public_path ||= self.root ? File.join(self.root, "public") : "public"
    end

    def public_path=(path)
      @public_path = path
    end
  end

  # The Initializer is responsible for processing the Rails configuration, such
  # as setting the $LOAD_PATH, requiring the right frameworks, initializing
  # logging, and more. It can be run either as a single command that'll just
  # use the default configuration, like this:
  #
  #   Rails::Initializer.run
  #
  # But normally it's more interesting to pass in a custom configuration
  # through the block running:
  #
  #   Rails::Initializer.run do |config|
  #     config.frameworks -= [ :action_mailer ]
  #   end
  #
  # This will use the default configuration options from Rails::Configuration,
  # but allow for overwriting on select areas.
  class Initializer
    class_inheritable_accessor :subclasses, :after_load_callbacks, :before_load_callbacks,
    :finished, :before_worker_shutdown_callbacks, :before_master_shutdown_callbacks
    
    self.subclasses, self.after_load_callbacks,
      self.before_load_callbacks, self.finished, self.before_master_shutdown_callbacks,
      self.before_worker_shutdown_callbacks = [], [], [], [], [], []

    class << self
      
      # Adds the inheriting class to the list of subclasses in a position
      # specified by the before and after methods.
      #
      # ==== Parameters
      # klass<Class>:: The class inheriting from Rails::BootLoader.
      #
      # ==== Returns
      # nil
      #
      # :api: plugin
      def inherited(klass)
        subclasses << klass.to_s
        super
      end

      # Execute this boot loader after the specified boot loader.
      #
      # ==== Parameters
      # klass<~to_s>::
      #   The boot loader class after which this boot loader should be run.
      #
      # ==== Returns
      # nil
      #
      # :api: plugin
      def after(klass)
        move_klass(klass, 1)
        nil
      end

      # Execute this boot loader before the specified boot loader.
      #
      # ==== Parameters
      # klass<~to_s>::
      #   The boot loader class before which this boot loader should be run.
      #
      # ==== Returns
      # nil
      #
      # :api: plugin
      def before(klass)
        move_klass(klass, 0)
        nil
      end

      # Move a class that is inside the bootloader to some place in the Array,
      # relative to another class.
      #
      # ==== Parameters
      # klass<~to_s>::
      #   The klass to move the bootloader relative to
      # where<Integer>::
      #   0 means insert it before; 1 means insert it after
      #
      # ==== Returns
      # nil
      #
      # :api: private
      def move_klass(klass, where)
        index = Rails::BootLoader.subclasses.index(klass.to_s)
        if index
          Rails::BootLoader.subclasses.delete(self.to_s)
          Rails::BootLoader.subclasses.insert(index + where, self.to_s)
        end
        nil
      end
      
      # Determines whether or not a specific bootloader has finished yet.
      #
      # ==== Parameters
      # bootloader<String, Class>:: The name of the bootloader to check.
      #
      # ==== Returns
      # Boolean:: Whether or not the bootloader has finished.
      #
      # :api: private
      def finished?(bootloader)
        self.finished.include?(bootloader.to_s)
      end

      # Execute a block of code after the app loads.
      #
      # ==== Parameters
      # &block::
      #   A block to be added to the callbacks that will be executed after the
      #   app loads.
      #
      # :api: public
      def after_app_loads(&block)
        after_load_callbacks << block
      end

      # Execute a block of code before the app loads but after dependencies load.
      #
      # ==== Parameters
      # &block::
      #   A block to be added to the callbacks that will be executed before the
      #   app loads.
      #
      # :api: public
      def before_app_loads(&block)
        before_load_callbacks << block
      end

      # Runs all boot loader classes by calling their run methods.
      #
      # ==== Returns
      # nil
      #
      # :api: plugin
      def run(command = nil, configuration = Configuration.new)
        Rails.configuration = configuration
        if command 
          Rails.const_get(command.to_s.camelize).run
        else
          yield configuration if block_given?
          Rails.started = true
          subklasses = subclasses.dup
          until subclasses.empty?
            time = Time.now.to_i
            bootloader = subclasses.shift
            if (ENV['DEBUG'] || $DEBUG || Merb::Config[:verbose]) && Rails.logger
              Rails.logger.debug!("Loading: #{bootloader}")
            end
            bootloader.constantize.run
            if (ENV['DEBUG'] || $DEBUG || Merb::Config[:verbose]) && Rails.logger
              Rails.logger.debug!("It took: #{Time.now.to_i - time}")
            end
            self.finished << bootloader
          end
          self.subclasses = subklasses
          nil
        end
      end
      
      def configuration
        Rails.configuration
      end
      
      def configuration=(configuration)
        Rails.configuration = configuration
      end
    end # << self
  end # Initializer
end

# Require rails initializers
require 'initializer/default_initializers'


# Needs to be duplicated from Active Support since its needed before Active
# Support is available. Here both Options and Hash are namespaced to prevent
# conflicts with other implementations AND with the classes residing in Active Support.
class Rails::OrderedOptions < Array #:nodoc:
  def []=(key, value)
    key = key.to_sym

    if pair = find_pair(key)
      pair.pop
      pair << value
    else
      self << [key, value]
    end
  end

  def [](key)
    pair = find_pair(key.to_sym)
    pair ? pair.last : nil
  end

  def method_missing(name, *args)
    if name.to_s =~ /(.*)=$/
      self[$1.to_sym] = args.first
    else
      self[name]
    end
  end

  private
    def find_pair(key)
      self.each { |i| return i if i.first == key }
      return false
    end
end
