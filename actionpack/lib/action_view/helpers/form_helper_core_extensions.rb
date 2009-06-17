class String
  def form_object_name
    self
  end

  def as_fields_for_form_object(args)
    args.first
  end
    
  def acts_like_model?
    false
  end
end

class Symbol
  def form_object_name
    self
  end

  def as_fields_for_form_object(args)
    args.first
  end

  def acts_like_model?
    false
  end
end

class Array
  def as_form_object
    last
  end
  
  def as_array
    self
  end
end

class Object
  def as_form_object
    self
  end

  def as_fields_for_form_object(args)
    as_form_object
  end
  
  def form_object_name
    ActionController::RecordIdentifier.singular_class_name(self)
  end
  
  def as_array
    [self]
  end
  
  def acts_like_model?
    true
  end
end