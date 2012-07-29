require 'active_support/concern'
require 'active_support/descendants_tracker'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/kernel/reporting'
require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/object/inclusion'

module ActiveSupport
  # \Callbacks are code hooks that are run at key points in an object's lifecycle.
  # The typical use case is to have a base class define a set of callbacks relevant
  # to the other functionality it supplies, so that subclasses can install callbacks
  # that enhance or modify the base functionality without needing to override
  # or redefine methods of the base class.
  #
  # Mixing in this module allows you to define the events in the object's lifecycle
  # that will support callbacks (via +ClassMethods.define_callbacks+), set the instance
  # methods, procs, or callback objects to be called (via +ClassMethods.set_callback+),
  # and run the installed callbacks at the appropriate times (via +run_callbacks+).
  #
  # Three kinds of callbacks are supported: before callbacks, run before a certain event;
  # after callbacks, run after the event; and around callbacks, blocks that surround the
  # event, triggering it when they yield. Callback code can be contained in instance
  # methods, procs or lambdas, or callback objects that respond to certain predetermined
  # methods. See +ClassMethods.set_callback+ for details.
  #
  #   class Record
  #     include ActiveSupport::Callbacks
  #     define_callbacks :save
  #
  #     def save
  #       run_callbacks :save do
  #         puts "- save"
  #       end
  #     end
  #   end
  #
  #   class PersonRecord < Record
  #     set_callback :save, :before, :saving_message
  #     def saving_message
  #       puts "saving..."
  #     end
  #
  #     set_callback :save, :after do |object|
  #       puts "saved"
  #     end
  #   end
  #
  #   person = PersonRecord.new
  #   person.save
  #
  # Output:
  #   saving...
  #   - save
  #   saved
  module Callbacks
    extend Concern

    included do
      extend ActiveSupport::DescendantsTracker
    end

    # Runs the callbacks for the given event.
    #
    # Calls the before and around callbacks in the order they were set, yields
    # the block (if given one), and then runs the after callbacks in reverse order.
    #
    # If the callback chain was halted, returns +false+. Otherwise returns the result
    # of the block, or +true+ if no block is given.
    #
    #   run_callbacks :save do
    #     save
    #   end
    #
    # 
    def run_callbacks(kind, &block)
      runner_name = self.class.__define_callbacks(kind, self)
      send(runner_name, &block)
    end

    private

    # A hook invoked everytime a before callback is halted.
    # This can be overriden in AS::Callback implementors in order
    # to provide better debugging/logging.
    def halted_callback_hook(filter)
    end

    class Callback #:nodoc:#
      # callback队列
      @@_callback_sequence = 0

      attr_accessor :chain, :filter, :kind, :options, :klass, :raw_filter

      def initialize(chain, filter, kind, options, klass)
        @chain, @kind, @klass = chain, kind, klass
        # 原来支持的per_key参数现在被deprecate了，用if和unless替代
        deprecate_per_key_option(options)
        normalize_options!(options)

        @raw_filter, @options = filter, options
        @filter               = _compile_filter(filter)
        recompile_options!
      end

      def deprecate_per_key_option(options)
        if options[:per_key]
          raise NotImplementedError, ":per_key option is no longer supported. Use generic :if and :unless options instead."
        end
      end

      def clone(chain, klass)
        obj                  = super()
        obj.chain            = chain
        obj.klass            = klass
        obj.options          = @options.dup
        obj.options[:if]     = @options[:if].dup
        obj.options[:unless] = @options[:unless].dup
        obj
      end

      # 如果option中是:if => true，改为:if => [true]
      # unless也一样
      def normalize_options!(options)
        options[:if] = Array(options[:if])
        options[:unless] = Array(options[:unless])
      end

      def name
        chain.name
      end

      def next_id
        @@_callback_sequence += 1
      end

      def matches?(_kind, _filter)
        @kind == _kind && @filter == _filter
      end

      def _update_filter(filter_options, new_options)
        filter_options[:if].concat(Array(new_options[:unless])) if new_options.key?(:unless)
        filter_options[:unless].concat(Array(new_options[:if])) if new_options.key?(:if)
      end

      def recompile!(_options)
        deprecate_per_key_option(_options)
        _update_filter(self.options, _options)

        recompile_options!
      end

      # Wraps code with filter
      #
      def apply(code)
        case @kind
        when :before
          # Here Document，以<<identifier或者<<"string"开头，当ruby找到接下来的某一行
          # 以identifier或者"string"开头的时候（前面不能有空白，即identifier或者
          # "string"必须顶行），就会认为字符串定义结束了。
          #
          # 当以<<-identifier或者<<-"string"开头，结束的行不用顶行写，可以有缩进。
          #
          # 如果是<<"string"，则字符串和双引号字符串一样
          # 如果是<<'string'，则字符串和单引号字符串一样
          #
          # 默认<<identifier和双引号字符串一样
          # 
          # 详见http://ruby-doc.org/docs/ProgrammingRuby/html/language.html
          <<-RUBY_EVAL
            if !halted && #{@compiled_options}
              # This double assignment is to prevent warnings in 1.9.3 as
              # the `result` variable is not always used except if the
              # terminator code refers to it.
              result = result = #{@filter}
              halted = (#{chain.config[:terminator]})
              if halted
                halted_callback_hook(#{@raw_filter.inspect.inspect})
              end
            end
            #{code}
          RUBY_EVAL
        when :after
          <<-RUBY_EVAL
          #{code}
          if #{!chain.config[:skip_after_callbacks_if_terminated] || "!halted"} && #{@compiled_options}
            #{@filter}
          end
          RUBY_EVAL
        when :around
          name = define_conditional_callback
          <<-RUBY_EVAL
          #{name}(halted) do
            #{code}
            value
          end
          RUBY_EVAL
        end
      end

      private

      # Compile around filters with conditions into proxy methods
      # that contain the conditions.
      #
      # For `set_callback :save, :around, :filter_name, :if => :condition':
      #
      # def _conditional_callback_save_17
      #   if condition
      #     filter_name do
      #       yield self
      #     end
      #   else
      #     yield self
      #   end
      # end
      def define_conditional_callback
        name = "_conditional_callback_#{@kind}_#{next_id}"
        @klass.class_eval <<-RUBY_EVAL,  __FILE__, __LINE__ + 1
          def #{name}(halted)
           if #{@compiled_options} && !halted
             #{@filter} do
               yield self
             end
           else
             yield self
           end
         end
        RUBY_EVAL
        name
      end

      # Options support the same options as filters themselves (and support
      # symbols, string, procs, and objects), so compile a conditional
      # expression based on the options
      def recompile_options!
        conditions = ["true"]

        unless options[:if].empty?
          conditions << Array(_compile_filter(options[:if]))
        end

        unless options[:unless].empty?
          conditions << Array(_compile_filter(options[:unless])).map {|f| "!#{f}"}
        end

        @compiled_options = conditions.flatten.join(" && ")
      end

      # Filters support:
      #
      #   Arrays::  Used in conditions. This is used to specify
      #             multiple conditions. Used internally to
      #             merge conditions from skip_* filters
      #   Symbols:: A method to call
      #   Strings:: Some content to evaluate
      #   Procs::   A proc to call with the object
      #   Objects:: An object with a before_foo method on it to call
      #
      # All of these objects are compiled into methods and handled
      # the same after this point:
      #
      #   Arrays::  Merged together into a single filter
      #   Symbols:: Already methods
      #   Strings:: class_eval'ed into methods
      #   Procs::   define_method'ed into methods
      #   Objects::
      #     a method is created that calls the before_foo method
      #     on the object.
      #
      # 所有类型的filter都被转换为一个方法
      def _compile_filter(filter)
        # 转换后方法的命名规范
        method_name = "_callback_#{@kind}_#{next_id}"
        case filter
        when Array
          filter.map {|f| _compile_filter(f)}
        when Symbol
          filter
        when String
          "(#{filter})"
        when Proc
          @klass.send(:define_method, method_name, &filter)
          return method_name if filter.arity <= 0

          method_name << (filter.arity == 1 ? "(self)" : " self, Proc.new ")
        else
          @klass.send(:define_method, "#{method_name}_object") { filter }

          _normalize_legacy_filter(kind, filter)
          scopes = Array(chain.config[:scope])
          method_to_call = scopes.map{ |s| s.is_a?(Symbol) ? send(s) : s }.join("_")

          @klass.class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
            def #{method_name}(&blk)
              #{method_name}_object.send(:#{method_to_call}, self, &blk)
            end
          RUBY_EVAL

          method_name
        end
      end

      def _normalize_legacy_filter(kind, filter)
        if !filter.respond_to?(kind) && filter.respond_to?(:filter)
          filter.singleton_class.class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
            def #{kind}(context, &block) filter(context, &block) end
          RUBY_EVAL
        elsif filter.respond_to?(:before) && filter.respond_to?(:after) && kind == :around && !filter.respond_to?(:around)
          ActiveSupport::Deprecation.warn("Filter object with #before and #after methods is deprecated. Define #around method instead.")
          def filter.around(context)
            should_continue = before(context)
            yield if should_continue
            after(context)
          end
        end
      end
    end

    # An Array with a compile method
    class CallbackChain < Array #:nodoc:#
      attr_reader :name, :config

      # name是目标方法，比如define_callback :save, :scope => 'before_save'则
      # 这里的name为:save，config为{:scope => 'before_save'}
      def initialize(name, config)
        @name = name
        @config = {
          :terminator => "false",
          :scope => [ :kind ]
        }.merge(config)
      end


      # compile 和工具方法apply生成了整个callback chain的代码
      #
      # ## 来自于compile
      # value = nil
      # halted = false
      # 
      # ## 来自于Callback.apply
      # if !halted && #{@compiled_options}
      #   # This double assignment is to prevent warnings in 1.9.3 as
      #   # the `result` variable is not always used except if the
      #   # terminator code refers to it.
      #   result = result = #{@filter}
      #   halted = (#{chain.config[:terminator]})
      #   if halted
      #     halted_callback_hook(#{@raw_filter.inspect.inspect})
      #   end
      # end
      #
      # ## 来自于compile
      # value = !halted && (!block_given? || yeild)
      # 
      # ## 返回值
      # value
      #
      def compile
        method = []
        method << "value = nil"
        method << "halted = false"

        callbacks = "value = !halted && (!block_given? || yield)"
        reverse_each do |callback|
          callbacks = callback.apply(callbacks)
        end
        method << callbacks

        method << "value"
        method.join("\n")
      end

    end

    module ClassMethods

      # This method defines callback chain method for the given kind
      # if it was not yet defined.
      # This generated method plays caching role.
      def __define_callbacks(kind, object) #:nodoc:
        name = __callback_runner_name(kind)
        # 除非生成的方法名字已经被用了
        unless object.respond_to?(name, true)
          # compile()方法返回方法体的字符串
          str = object.send("_#{kind}_callbacks").compile

          # 定义实例方法，并且将方法设置为protected
          class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
            def #{name}() #{str} end
            protected :#{name}
          RUBY_EVAL
        end
        name
      end

      def __reset_runner(symbol)
        name = __callback_runner_name(symbol)
        undef_method(name) if method_defined?(name)
      end

      def __callback_runner_name(kind)
        "_run__#{self.name.hash.abs}__#{kind}__callbacks"
      end

      # This is used internally to append, prepend and skip callbacks to the
      # CallbackChain.
      #
      def __update_callbacks(name, filters = [], block = nil) #:nodoc:
        # 默认取before
        type = filters.first.in?([:before, :after, :around]) ? filters.shift : :before
        # 最后一个参数是Hash，则取出来，否者为{}
        options = filters.last.is_a?(Hash) ? filters.pop : {}
        # 如果callback是block，则将callback加入filter队列
        filters.unshift(block) if block

        # 这里的name是目标方法的名字，如果为save()定义了filter，则创建一个_save_callbacks的队列
        ([self] + ActiveSupport::DescendantsTracker.descendants(self)).reverse.each do |target|
          chain = target.send("_#{name}_callbacks")
          yield target, chain.dup, type, filters, options
          target.__reset_runner(name)
        end
      end

      # Install a callback for the given event.
      #
      #   set_callback :save, :before, :before_meth
      #   set_callback :save, :after,  :after_meth, :if => :condition
      #   set_callback :save, :around, lambda { |r| stuff; result = yield; stuff }
      #
      # The second arguments indicates whether the callback is to be run +:before+,
      # +:after+, or +:around+ the event. If omitted, +:before+ is assumed. This
      # means the first example above can also be written as:
      #
      #   set_callback :save, :before_meth
      #
      # The callback can specified as a symbol naming an instance method; as a proc,
      # lambda, or block; as a string to be instance evaluated; or as an object that
      # responds to a certain method determined by the <tt>:scope</tt> argument to
      # +define_callback+.
      #
      # 第一个参数是方法名称，即目标方法
      #
      # 第二个参数是callback类型（kind或者type），可以是before,after,around，默认是before
      #
      # 第三个参数，callback可以是
      # 
      # * 一个实例方法，用symbol制定，方法名字嘛
      # * 一段代码，用proc，lambda或者block，和一个匿名方法一样，在运行时的当前对象
      #   实例上下文中被执行
      # * 一个字符串，同上
      # * 一个对象，define_callback方法中:scope参数代表的那个方法被调用（scope这个参
      #   数名感觉很一般啊）
      #
      #
      # options可以是
      # 
      # * if，条件
      # * unless，条件
      # * prepend，添加在最前面
      #
      # If a proc, lambda, or block is given, its body is evaluated in the context
      # of the current object. It can also optionally accept the current object as
      # an argument.
      #
      # Before and around callbacks are called in the order that they are set; after
      # callbacks are called in the reverse order.
      # 
      # Around callbacks can access the return value from the event, if it
      # wasn't halted, from the +yield+ call.
      #
      # ===== Options
      #
      # * <tt>:if</tt> - A symbol naming an instance method or a proc; the callback
      #   will be called only when it returns a true value.
      # * <tt>:unless</tt> - A symbol naming an instance method or a proc; the callback
      #   will be called only when it returns a false value.
      # * <tt>:prepend</tt> - If true, the callback will be prepended to the existing
      #   chain rather than appended.
      def set_callback(name, *filter_list, &block)
        mapped = nil

        __update_callbacks(name, filter_list, block) do |target, chain, type, filters, options|
          mapped ||= filters.map do |filter|
            Callback.new(chain, filter, type, options.dup, self)
          end

          filters.each do |filter|
            chain.delete_if {|c| c.matches?(type, filter) }
          end

          options[:prepend] ? chain.unshift(*(mapped.reverse)) : chain.push(*mapped)

          target.send("_#{name}_callbacks=", chain)
        end
      end

      # Skip a previously set callback. Like +set_callback+, <tt>:if</tt> or <tt>:unless</tt>
      # options may be passed in order to control when the callback is skipped.
      #
      #   class Writer < Person
      #      skip_callback :validate, :before, :check_membership, :if => lambda { self.age > 18 }
      #   end
      def skip_callback(name, *filter_list, &block)
        __update_callbacks(name, filter_list, block) do |target, chain, type, filters, options|
          filters.each do |filter|
            filter = chain.find {|c| c.matches?(type, filter) }

            if filter && options.any?
              new_filter = filter.clone(chain, self)
              chain.insert(chain.index(filter), new_filter)
              new_filter.recompile!(options)
            end

            chain.delete(filter)
          end
          target.send("_#{name}_callbacks=", chain)
        end
      end

      # Remove all set callbacks for the given event.
      def reset_callbacks(symbol)
        callbacks = send("_#{symbol}_callbacks")

        ActiveSupport::DescendantsTracker.descendants(self).each do |target|
          chain = target.send("_#{symbol}_callbacks").dup
          callbacks.each { |c| chain.delete(c) }
          target.send("_#{symbol}_callbacks=", chain)
          target.__reset_runner(symbol)
        end

        self.send("_#{symbol}_callbacks=", callbacks.dup.clear)

        __reset_runner(symbol)
      end

      # Define sets of events in the object lifecycle that support callbacks.
      #
      #   define_callbacks :validate
      #   define_callbacks :initialize, :save, :destroy
      #
      # ===== Options
      #
      # * <tt>:terminator</tt> - Determines when a before filter will halt the callback
      #   chain, preventing following callbacks from being called and the event from being
      #   triggered. This is a string to be eval'ed. The result of the callback is available
      #   in the <tt>result</tt> variable.
      #
      #     define_callbacks :validate, :terminator => "result == false"
      #
      #   In this example, if any before validate callbacks returns +false+,
      #   other callbacks are not executed. Defaults to "false", meaning no value
      #   halts the chain.
      #
      # * <tt>:skip_after_callbacks_if_terminated</tt> - Determines if after callbacks should be terminated
      #   by the <tt>:terminator</tt> option. By default after callbacks executed no matter
      #   if callback chain was terminated or not.
      #   Option makes sence only when <tt>:terminator</tt> option is specified.
      #
      # * <tt>:scope</tt> - Indicates which methods should be executed when an object
      #   is used as a callback.
      #
      #     class Audit
      #       def before(caller)
      #         puts 'Audit: before is called'
      #       end
      #
      #       def before_save(caller)
      #         puts 'Audit: before_save is called'
      #       end
      #     end
      #
      #     class Account
      #       include ActiveSupport::Callbacks
      #
      #       define_callbacks :save
      #       set_callback :save, :before, Audit.new
      #
      #       def save
      #         run_callbacks :save do
      #           puts 'save in main'
      #         end
      #       end
      #     end
      #
      #   In the above case whenever you save an account the method <tt>Audit#before</tt> will
      #   be called. On the other hand
      #
      #     define_callbacks :save, :scope => [:kind, :name]
      #
      #   would trigger <tt>Audit#before_save</tt> instead. That's constructed by calling
      #   <tt>#{kind}_#{name}</tt> on the given instance. In this case "kind" is "before" and
      #   "name" is "save". In this context +:kind+ and +:name+ have special meanings: +:kind+
      #   refers to the kind of callback (before/after/around) and +:name+ refers to the
      #   method on which callbacks are being defined.
      #
      #   A declaration like
      #
      #     define_callbacks :save, :scope => [:name]
      #
      #   would call <tt>Audit#save</tt>.
      def define_callbacks(*callbacks)
        # 如果参数的最后一个是Hash，则取出来，这个参数是:scope配置信息
        config = callbacks.last.is_a?(Hash) ? callbacks.pop : {}
        # 对除去配置信息的列表进行处理
        callbacks.each do |callback|
          # 定义类变量，比如define_callbacks :save，即目标方法为save，则定义了一个
          # 名称为_save_callbacks的类变量，并且赋值为CallbackChain，
          # CallbackChain实际上是一个数组
          # 
          # http://apidock.com/rails/Class/class_attribute
          class_attribute "_#{callback}_callbacks"
          send("_#{callback}_callbacks=", CallbackChain.new(callback, config))
        end
      end
    end
  end
end
      def __define_callbacks(kind, object) #:nodoc:
