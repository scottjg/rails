module ActionController #:nodoc:
  module Flash
    extend ActiveSupport::Concern

    included do
      class_attribute :_flash_types
      self._flash_types = []

      delegate :flash, :to => :request
      add_flash_type :alert, :notice
    end

    module ClassMethods
      def add_flash_type(*types)
        types.each do |type|
          delegate type, :to => "request.flash"
          helper_method type

          ActionDispatch::Flash::FlashNow.class_eval <<-EOS
            def #{type}=(message)
              self[:#{type}] = message
            end
          EOS

          ActionDispatch::Flash::FlashHash.class_eval <<-EOS
            def #{type}
              self[:#{type}]
            end
            def #{type}=(message)
              self[:#{type}] = message
            end
          EOS

          _flash_types << type
        end
      end
    end
    protected
      def redirect_to(options = {}, response_status_and_flash = {}) #:doc:
        self.class._flash_types.each do |flash_type|
          if type = response_status_and_flash.delete(flash_type)
            flash[flash_type] = type
          end
        end

        if other_flashes = response_status_and_flash.delete(:flash)
          flash.update(other_flashes)
        end

        super(options, response_status_and_flash)
      end
  end
end
