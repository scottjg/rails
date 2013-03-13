require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/logger_silence'
require 'logger'

module ActiveSupport
  class Logger < ::Logger
    include LoggerSilence

    def self.file_for_logging(path, opts = "a")
      unless File.exist? File.dirname path
        FileUtils.mkdir_p File.dirname path
      end

      File.open(path, opts)
    rescue StandardError
      logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDERR))
      logger.level = config.log_level = ActiveSupport::Logger::WARN
      logger.warn(
        "Rails Error: Unable to access log file. Please ensure that #{path} exists and is chmod 0666. " +
        "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
      )
      STDERR
    end

    # Broadcasts logs to multiple loggers.
    def self.broadcast(logger) # :nodoc:
      Module.new do
        define_method(:add) do |*args, &block|
          logger.add(*args, &block)
          super(*args, &block)
        end

        define_method(:<<) do |x|
          logger << x
          super(x)
        end

        define_method(:close) do
          logger.close
          super()
        end

        define_method(:progname=) do |name|
          logger.progname = name
          super(name)
        end

        define_method(:formatter=) do |formatter|
          logger.formatter = formatter
          super(formatter)
        end

        define_method(:level=) do |level|
          logger.level = level
          super(level)
        end
      end
    end

    def initialize(*args)
      super
      @formatter = SimpleFormatter.new
    end

    # Simple formatter which only displays the message.
    class SimpleFormatter < ::Logger::Formatter
      # This method is invoked when a log event occurs
      def call(severity, timestamp, progname, msg)
        "#{String === msg ? msg : msg.inspect}\n"
      end
    end
  end
end
