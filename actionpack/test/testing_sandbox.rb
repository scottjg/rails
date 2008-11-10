module TestingSandbox
  # Temporarily replaces KCODE for the block
  def with_kcode(kcode)
    if RUBY_VERSION < '1.9'
      old_kcode, $KCODE = $KCODE, kcode
      begin
        yield
      ensure
        $KCODE = old_kcode
      end
    else
      yield
    end
  end
  
  def with_formatted_routes_enabled( &block )
    with_formatted_routes( true, &block )
  end
  
  def with_formatted_routes_disabled( &block )
    with_formatted_routes( false, &block )
  end
  
  def with_formatted_routes( formatted, &block )
    old_formatted_routes = ActionController::Base.formatted_routes
    begin
      ActionController::Base.formatted_routes = formatted
      yield
    ensure
      ActionController::Base.formatted_routes = old_formatted_routes  
    end 
  end
  
end
