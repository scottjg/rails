class FalseClass
  AS_JSON = ActiveSupport::JSON::Variable.new('false').freeze

  def as_json(options = nil) #:nodoc:
    false
  end
end
