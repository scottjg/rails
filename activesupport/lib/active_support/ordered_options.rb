require 'active_support/ordered_hash'

# Usually key value pairs are handled something like this:
#
#   h = ActiveSupport::OrderedOptions.new
#   h[:boy] = 'John'
#   h[:girl] = 'Mary'
#   h[:boy]  # => 'John'
#   h[:girl] # => 'Mary'
#
# Using <tt>OrderedOptions</tt> above code could be reduced to:
#
#   h = ActiveSupport::OrderedOptions.new
#   h.boy = 'John'
#   h.girl = 'Mary'
#   h.boy  # => 'John'
#   h.girl # => 'Mary'
#
module ActiveSupport #:nodoc:
  class OrderedOptions < OrderedHash
    alias_method :_get, :[] # preserve the original #[] method
    protected :_get # make it protected

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

  class InheritableOptions < OrderedOptions
    def initialize(parent = nil)
      if parent.kind_of?(OrderedOptions)
        # use the faster _get when dealing with OrderedOptions
        super() { |h,k| parent._get(k) }
      elsif parent
        super() { |h,k| parent[k] }
      else
        super()
      end
    end

    def inheritable_copy
      self.class.new(self)
    end
  end
end
