require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/module/aliasing'

module ActiveSupport
  module Memoizable
    def self.memoized_ivar_for(symbol)
      "@_memoized_#{symbol.to_s.sub(/\?\Z/, '_query').sub(/!\Z/, '_bang')}".to_sym
    end

    module InstanceMethods
      def self.included(base)
        base.class_eval do
          unless base.method_defined?(:freeze_without_memoizable)
            alias_method_chain :freeze, :memoizable
          end
        end
      end

      def freeze_with_memoizable
        memoize_all unless frozen?
        freeze_without_memoizable
      end

      def memoize_all
        prime_cache
      end

      def unmemoize_all
        flush_cache
      end

      def prime_cache(*syms)
        syms = self.class.memoized_methods if syms.empty?
        syms.each do |sym|
          m = :"_unmemoized_#{sym}"
          if method(m).arity == 0
            __send__(sym)
          else
            ivar = ActiveSupport::Memoizable.memoized_ivar_for(sym)
            instance_variable_set(ivar, {})
          end
        end
      end

      def flush_cache(*syms, &block)
        syms = self.class.memoized_methods if syms.empty?
        syms.each do |sym|
          ivar = ActiveSupport::Memoizable.memoized_ivar_for(sym)
          instance_variable_get(ivar).clear if instance_variable_defined?(ivar)
        end
      end
    end

    def memoized_methods
      @_memoized_methods ||= []
    end

    def memoize(*symbols)
      symbols.each do |symbol|
        memoized_methods.push(symbol.to_s).uniq!

        original_method = :"_unmemoized_#{symbol}"
        memoized_ivar = ActiveSupport::Memoizable.memoized_ivar_for(symbol)

        class_eval <<-EOS, __FILE__, __LINE__ + 1
          include InstanceMethods                                                  # include InstanceMethods
                                                                                   #
          if method_defined?(:#{original_method})                                  # if method_defined?(:_unmemoized_mime_type)
            raise "Already memoized #{symbol}"                                     #   raise "Already memoized mime_type"
          end                                                                      # end
          alias #{original_method} #{symbol}                                       # alias _unmemoized_mime_type mime_type
                                                                                   #
          if instance_method(:#{symbol}).arity == 0                                # if instance_method(:mime_type).arity == 0
            def #{symbol}(reload = false)                                          #   def mime_type(reload = false)
              if reload || !defined?(#{memoized_ivar}) || #{memoized_ivar}.empty?  #     if reload || !defined?(@_memoized_mime_type) || @_memoized_mime_type.empty?
                #{memoized_ivar} = [#{original_method}]                            #       @_memoized_mime_type = [_unmemoized_mime_type]
              end                                                                  #     end
              #{memoized_ivar}[0]                                                  #     @_memoized_mime_type[0]
            end                                                                    #   end
          else                                                                     # else
            def #{symbol}(*args)                                                   #   def mime_type(*args)
              #{memoized_ivar} ||= {} unless frozen?                               #     @_memoized_mime_type ||= {} unless frozen?
              reload = args.pop if args.last == true || args.last == :reload       #     reload = args.pop if args.last == true || args.last == :reload
                                                                                   #
              if defined?(#{memoized_ivar}) && #{memoized_ivar}                    #     if defined?(@_memoized_mime_type) && @_memoized_mime_type
                if !reload && #{memoized_ivar}.has_key?(args)                      #       if !reload && @_memoized_mime_type.has_key?(args)
                  #{memoized_ivar}[args]                                           #         @_memoized_mime_type[args]
                elsif #{memoized_ivar}                                             #       elsif @_memoized_mime_type
                  #{memoized_ivar}[args] = #{original_method}(*args)               #         @_memoized_mime_type[args] = _unmemoized_mime_type(*args)
                end                                                                #       end
              else                                                                 #     else
                #{original_method}(*args)                                          #       _unmemoized_mime_type(*args)
              end                                                                  #     end
            end                                                                    #   end
          end                                                                      # end
                                                                                   #
          if private_method_defined?(#{original_method.inspect})                   # if private_method_defined?(:_unmemoized_mime_type)
            private #{symbol.inspect}                                              #   private :mime_type
          end                                                                      # end
        EOS
      end
    end
  end
end
