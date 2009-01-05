class Time
  def to_json(options = nil) #:nodoc:
    # to_datetime.to_json(options)
    %("#{strftime("%Y/%m/%d %H:%M:%S %z")}")
  end
end
