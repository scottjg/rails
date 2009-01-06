# OrderedHash is namespaced to prevent conflicts with other implementations
module ActiveSupport
  # Hash is ordered in Ruby 1.9!
  if RUBY_VERSION >= '1.9'
    OrderedHash = ::Hash
  else
    class OrderedHash < Array #:nodoc:
      alias_method :each_pair, :each

      def []=(key, value)
        if pair = assoc(key)
          pair[1] = value
        else
          self << [key, value]
          value
        end
      end

      def [](key)
        pair = assoc(key)
        pair ? pair.last : nil
      end

      def keys
        collect { |key, value| key }
      end

      def values
        collect { |key, value| value }
      end

      def to_hash
        returning({}) do |hash|
          each { |array| hash[array[0]] = array[1] }
        end
      end
    end
  end
end

class OrderedOptions < ActiveSupport::OrderedHash #:nodoc:
  def []=(key, value)
    super(key.to_sym, value)
  end

  def [](key)
    super(key.to_sym)
  end

  def method_missing(name, *args)
    if name.to_s =~ /(.*)=$/
      self[$1.to_sym] = args.first
    else
      self[name]
    end
  end
end
