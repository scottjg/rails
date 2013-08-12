module ActiveSupport
  # A class with no predefined methods that behaves similarly to Builder's
  # BlankSlate. Used for proxy classes.
  class ProxyObject < ::BasicObject
    undef_method :== if method_defined? :==
    undef_method :equal? if method_defined? :equal?

    # Let ActiveSupport::ProxyObject at least raise exceptions.
    def raise(*args)
      ::Object.send(:raise, *args)
    end
  end
end
