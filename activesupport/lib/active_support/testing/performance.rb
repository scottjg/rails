require 'fileutils'
begin
  require 'rails/version'
rescue LoadError
  # Ignore
end
require 'active_support/concern'
require 'active_support/core_ext/class/delegating_attributes'
require 'active_support/core_ext/string/inflections'

module ActiveSupport
  module Testing
    module Performance
      extend ActiveSupport::Concern

      included do
        superclass_delegating_accessor :profile_options
        superclass_delegating_accessor :benchmark_options
        self.profile_options = {}
        self.benchmark_options = {}

        if defined?(MiniTest::Assertions) && TestCase < MiniTest::Assertions
          include ForMiniTest
        else
          include ForClassicTestUnit
        end
      end

      def self.run_mode
        if ENV['benchmark'] or ARGV.include?('--benchmark') # HAX for rake test
          :benchmark
        elsif ENV['profile'] or ARGV.include?('--profile') # HAX for rake test
          :profile
        else
          raise "Should I run in benchmarking mode or profiling mode?"
        end
      end

      # each implementation should define metrics and freeze the defaults
      DEFAULTS= {
        benchmark: {
          :runs => 4,
          :output => 'tmp/performance',
          :benchmark => true,
        },
        profile: {
          :runs => 1,
          :output => 'tmp/performance',
          :benchmark => false,
        },
      }

      def full_profile_options
        run_mode= ActiveSupport::Testing::Performance.run_mode
        defaults= DEFAULTS[run_mode]
        override= public_send("#{run_mode}_options")
        defaults.merge(override)
      end

      def full_test_name
        "#{self.class.name}##{method_name}"
      end

      module ForMiniTest
        def run(runner)
          @runner = runner

          run_warmup
          if full_profile_options && metrics = full_profile_options[:metrics]
            metrics.each do |metric_name|
              if klass = Metrics[metric_name.to_sym]
                run_profile(klass.new)
              end
            end
          end

          return
        end

        def run_test(metric, mode)
          result = '.'
          begin
            run_callbacks :setup
            setup
            metric.send(mode) { __send__ method_name }
          rescue Exception => e
            result = @runner.puke(self.class, method_name, e)
          ensure
            begin
              teardown
              run_callbacks :teardown, :enumerator => :reverse_each
            rescue Exception => e
              result = @runner.puke(self.class, method_name, e)
            end
          end
          result
        end
      end

      module ForClassicTestUnit
        def run(result)
          return if method_name =~ /^default_test$/

          yield(self.class::STARTED, name)
          @_result = result

          run_warmup
          if full_profile_options && metrics = full_profile_options[:metrics]
            metrics.each do |metric_name|
              if klass = Metrics[metric_name.to_sym]
                run_profile(klass.new)
                result.add_run
              else
                puts '%20s: unsupported' % metric_name
              end
            end
          end

          yield(self.class::FINISHED, name)
        end

        def run_test(metric, mode)
          run_callbacks :setup
          setup
          metric.send(mode) { __send__ @method_name }
        rescue ::Test::Unit::AssertionFailedError => e
        add_failure(e.message, e.backtrace)
        rescue StandardError, ScriptError => e
          add_error(e)
        ensure
          begin
            teardown
            run_callbacks :teardown, :enumerator => :reverse_each
          rescue ::Test::Unit::AssertionFailedError => e
            add_failure(e.message, e.backtrace)
          rescue StandardError, ScriptError => e
            add_error(e)
          end
        end
      end

      protected
        # overridden by each implementation
        def run_gc; end

        def run_warmup
          run_gc

          time = Metrics::Time.new
          run_test(time, :benchmark)
          puts "%s (%s warmup)" % [full_test_name, time.format(time.total)]

          run_gc
        end

        def run_profile(metric)
          klass = full_profile_options[:benchmark] ? Benchmarker : Profiler
          performer = klass.new(self, metric)

          performer.run
          puts performer.report
          performer.record
        end

      class Performer
        delegate :run_test, :full_profile_options, :full_test_name, :to => :@harness

        def initialize(harness, metric)
          @harness, @metric, @supported = harness, metric, false
        end

        def report
          if @supported
            rate = @total / full_profile_options[:runs]
            '%20s: %s' % [@metric.name, @metric.format(rate)]
          else
            '%20s: unsupported' % @metric.name
          end
        end

        protected
          def output_filename
            "#{full_profile_options[:output]}/#{full_test_name}_#{@metric.name}"
          end
      end

      # overridden by each implementation
      class Profiler < Performer
        def time_with_block
          before = Time.now
          yield
          Time.now - before
        end

        def run;    end
        def record; end
      end

      class Benchmarker < Performer
        def initialize(*args)
          super
          @supported = @metric.respond_to?('measure')
        end

        def run
          return unless @supported

          full_profile_options[:runs].to_i.times { run_test(@metric, :benchmark) }
          @total = @metric.total
        end

        def record
          avg = @metric.total / full_profile_options[:runs].to_i
          now = Time.now.utc.xmlschema
          with_output_file do |file|
            file.puts "#{avg},#{now},#{environment}"
          end
        end

        def environment
          unless defined? @env
            app = "#{$1}.#{$2}" if File.directory?('.git') && `git branch -v` =~ /^\* (\S+)\s+(\S+)/

            rails = defined?(Rails) ? Rails::VERSION::STRING : nil
            if File.directory?('vendor/rails/.git')
              Dir.chdir('vendor/rails') do
                rails += ".#{$1}.#{$2}" if `git branch -v` =~ /^\* (\S+)\s+(\S+)/
              end
            end

            ruby = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
            ruby += "-#{RUBY_VERSION}.#{RUBY_PATCHLEVEL}"

            v= [app]
            v<< rails if rails
            v<< ruby
            v<< RUBY_PLATFORM
            @env = v * ','
          end

          @env
        end

        protected
          HEADER = 'measurement,created_at,app,rails,ruby,platform'
          HEADER.sub!(',rails,',',') unless defined?(Rails)

          def with_output_file
            fname = output_filename

            if new = !File.exist?(fname)
              FileUtils.mkdir_p(File.dirname(fname))
            end

            File.open(fname, 'ab') do |file|
              file.puts(HEADER) if new
              yield file
            end
          end

          def output_filename
            "#{super}.csv"
          end
      end

      module Metrics
        def self.[](name)
          const_get(name.to_s.camelize)
        rescue NameError
          nil
        end

        class Base

          attr_reader :total
          class_attribute :formatter

          def initialize
            @total = 0
          end

          def name
            @name ||= self.class.name.demodulize.underscore
          end

          def benchmark
            with_gc_stats do
              before = measure
              yield
              @total += (measure - before)
            end
          end

          # overridden by each implementation
          def profile; end

          protected
            # overridden by each implementation
            def with_gc_stats; end
        end

        class Time < Base
          def measure
            ::Time.now.to_f
          end

          def format(measurement)
            if measurement < 1
              '%d ms' % (measurement * 1000)
            else
              '%.2f sec' % measurement
            end
          end
        end

        class Amount < Base
          def format(measurement)
            if self.class.formatter.present?
              self.class.formatter.call(measurement.floor)
            else
              measurement.floor
            end
          end
        end

        class DigitalInformationUnit < Base
          def format(measurement)
            if self.class.formatter.present?
              self.class.formatter.call(measurement)
            else
              "#{measurement} Bytes"
            end
          end
        end

        # each implementation provides its own metrics like ProcessTime, Memory or GcRuns
      end
    end
  end
end

RUBY_ENGINE = 'ruby' unless defined?(RUBY_ENGINE) # mri 1.8
case RUBY_ENGINE
  when 'ruby'   then require 'active_support/testing/performance/ruby'
  when 'rbx'    then require 'active_support/testing/performance/rubinius'
  when 'jruby'  then require 'active_support/testing/performance/jruby'
  else
    $stderr.puts 'Your ruby interpreter is not supported for benchmarking.'
    exit
end
