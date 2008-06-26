module ActiveModel
  module DeprecatedErrorMethods
    def on(attribute)
      ActiveSupport::Deprecation.warn "Errors#on have been deprecated, use Errors#[] instead"
      errs = self[attribute]
      case errs.size
      when 0
        ActiveSupport::Deprecation.warn "Errors#on / Errors#[] returning nil is deprecated, always expect an array, and check errors[attr].empty? instead"
        nil
      when 1
        ActiveSupport::Deprecation.warn "Errors#on / Errors#[] returning a single value is deprecated, always expect an array instead"
        errs[0]
      else
        errs
      end
    end

    def on_base
      ActiveSupport::Deprecation.warn "Errors#on_base have been deprecated, use Errors#[:base] instead"
      on(:base)
    end

    def add(attribute, msg = Errors.default_error_messages[:invalid])
      ActiveSupport::Deprecation.warn "Errors#add(attribute, msg) has been deprecated, use Errors#[attribute] << msg instead"
      self[attribute] << msg
    end

    def add_to_base(msg)
      ActiveSupport::Deprecation.warn "Errors#add_to_base(msg) has been deprecated, use Errors#[:base] << msg instead"
      self[:base] << msg
    end
    
    def add_on_blank(attributes, msg = ActiveModel::Errors::default_error_messages[:blank])
      ActiveSupport::Deprecation.warn "Errors#add_on_blank(attributes, msg) has been deprecated, use Errors#[attribute] << msg if object.blank? instead"
      for attr in [attributes].flatten
        value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s) : @base[attr.to_s]
        add(attr, msg) if value.blank?
      end
    end
    
    def add_on_empty(attributes, msg = ActiveModel::Errors::default_error_messages[:empty])
      for attr in [attributes].flatten
        value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s) : @base[attr.to_s]
        is_empty = value.respond_to?("empty?") ? value.empty? : false
        add(attr, msg) unless !value.nil? && !is_empty
      end
    end
  
    def invalid?(attribute)
      ActiveSupport::Deprecation.warn "Errors#invalid?(attribute) has been deprecated, use Errors#[attribute].any? instead"
      self[attribute].any?
    end

    def full_messages
      ActiveSupport::Deprecation.warn "Errors#full_messages has been deprecated, use Errors#to_a instead"
      to_a
    end

    def each_full
      ActiveSupport::Deprecation.warn "Errors#each_full has been deprecated, use Errors#to_a.each instead"
      to_a.each { |error| yield error }
    end
  end
end