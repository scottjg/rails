module ActiveModel
  module MassAssignmentSecurity
    extent ActiveSupport::Concern

     module ClassMethods
       def attr_protected(*args)
        raise "`attr_protected` is extracted out of Rails into a gem. " \
          "Please add `protected_attributes` to your Gemfile to use it."
       end

       def attr_accessible(*args)
        raise "`attr_accessible` is extracted out of Rails into a gem. " \
          "Please add `protected_attributes` to your Gemfile to use it."
       end
     end
  end
end
