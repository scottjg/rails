require 'benchmark'

module ActionController #:nodoc:
  # The benchmarking module times the performance of actions and reports to the logger. If the Active Record
  # package has been included, a separate timing section for database calls will be added as well.
  module Benchmarking #:nodoc:
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        alias_method_chain :perform_action, :benchmark
        alias_method_chain :render, :benchmark
      end
    end

    module ClassMethods
      # Log and benchmark the workings of a single block and silence whatever logging that may have happened inside it
      # (unless <tt>use_silence</tt> is set to false).
      #
      # The benchmark is only recorded if the current level of the logger matches the <tt>log_level</tt>, which makes it
      # easy to include benchmarking statements in production software that will remain inexpensive because the benchmark
      # will only be conducted if the log level is low enough.
      def benchmark(title, log_level = Logger::DEBUG, use_silence = true)
        if logger && logger.level == log_level
          result = nil
          ms = Benchmark.ms { result = use_silence ? silence { yield } : yield }
          logger.add(log_level, "#{title} (#{('%.1f' % ms)}ms)")
          result
        else
          yield
        end
      end

      # Silences the logger for the duration of the block.
      def silence
        old_logger_level, logger.level = logger.level, Logger::ERROR if logger
        yield
      ensure
        logger.level = old_logger_level if logger
      end
    end

    protected
      def render_with_benchmark(options = nil, extra_options = {}, &block)
        ActiveSupport::Notifications.instrument("render.action_controller", {:options => options, :extra_options => extra_options) do |payload|
          if Object.const_defined?("ActiveRecord") && ActiveRecord::Base.connected?
            db_runtime = ActiveRecord::Base.connection.reset_runtime
          end

          render_output = nil
          @view_runtime = Benchmark.ms { render_output = render_without_benchmark(options, extra_options, &block) }

          if Object.const_defined?("ActiveRecord") && ActiveRecord::Base.connected?
            @db_rt_before_render = db_runtime
            @db_rt_after_render = ActiveRecord::Base.connection.reset_runtime
            @view_runtime -= @db_rt_after_render
          end
          render_output
        end
      end

    private
      def perform_action_with_benchmark
        started = Time.now
        ms = [Benchmark.ms { perform_action_without_benchmark }, 0.01].max
        finished = Time.now

        parameters = respond_to?(:filter_parameters) ? filter_parameters(params) : params.dup
        parameters = parameters.except('controller', 'action', 'format', '_method', 'protocol')

        payload = payload.merge({
          :uuid          => (request.uuid if request.respond_to?(:uuid)),
          :env           => request.env,
          :controller    => self.class.name,
          :action        => self.action_name,
          :full_action   => "#{params[:controller]}##{params[:action]}",
          :params        => parameters,
          :format        => request.format.to_sym,
          :method        => request.method,
          :path          => (request.fullpath rescue "unknown"),
          :status        => response.status.to_s[0..2],
          :location      => response.location
        })

        logging_view          = defined?(@view_runtime)
        logging_active_record = Object.const_defined?("ActiveRecord") && ActiveRecord::Base.connected?

        if logging_active_record
          db_runtime = ActiveRecord::Base.connection.reset_runtime
          db_runtime += @db_rt_before_render if @db_rt_before_render
          db_runtime += @db_rt_after_render if @db_rt_after_render

          payload[:db_runtime] = db_runtime
        end

        if logging_view
          payload[:view_runtime] = @view_runtime
        end

        ActiveSupport::Notifications.publish("perform_action.action_controller", started, finished, ActiveSupport::Notifications.instrumenter.id, payload)
        response.headers["X-Runtime"] = "%.0f" % ms
      end

      def view_runtime
        "View: %.0f" % @view_runtime
      end

      def active_record_runtime
        db_runtime = ActiveRecord::Base.connection.reset_runtime
        db_runtime += @db_rt_before_render if @db_rt_before_render
        db_runtime += @db_rt_after_render if @db_rt_after_render
        "DB: %.0f" % db_runtime
      end
  end
end
