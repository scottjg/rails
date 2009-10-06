module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module String #:nodoc:
      module OutputSafety
        def self.included(base)
          base.class_eval do
            alias_method :add_without_safety, :+
            alias_method :+, :add_with_safety
            alias_method_chain :concat, :safety
            undef_method :<<
            alias_method :<<, :concat_with_safety
          end
        end

  def html_safe!
    @_rails_html_safe = true
    self
  end
  
  def html_safe
    dup.html_safe!
  end
end