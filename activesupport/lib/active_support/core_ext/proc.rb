require "active_support/core_ext/kernel/singleton_class"
require "active_support/deprecation"

class Proc #:nodoc:
  def bind(object)
    warn_text = 'Proc#bind is deprecated and will be removed in future versions'
    ActiveSupport::Deprecation.warn warn_text, caller

    block, time = self, Time.now
    object.class_eval do
      method_name = "__bind_#{time.to_i}_#{time.usec}"
      define_method(method_name, &block)
      method = instance_method(method_name)
      remove_method(method_name)
      method
    end.bind(object)
  end
end
