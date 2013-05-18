class TrueClass
  AS_JSON = ActiveSupport::JSON::Variable.new('true').freeze

  def as_json(options = nil) #:nodoc:
    true
  end
end
