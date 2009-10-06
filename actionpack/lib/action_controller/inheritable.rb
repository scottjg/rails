module ActionController
  module Inheritable
    private

    def find_template_inheritable(controller)
      klass = controller.class
      parent_controllers_classes = []
      until klass == ActionController::Base
        parent_controllers_classes << klass
        klass = klass.superclass
      end

      template = nil
      last_exc = nil
      [controller.class, parent_controllers_classes].flatten.each do |cc|
        begin
          template = yield cc
          return template if template
        rescue ActionView::MissingTemplate
          last_exc = $!
        end
      end
      raise last_exc #FIXME this exception should contain all path sets, not only the last one
    end
  end
end

