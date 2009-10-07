class String
  def html_safe?
    defined?(@_rails_html_safe) && @_rails_html_safe
  end

  def html_safe!
    @_rails_html_safe = true
    self
  end
  
  def html_safe
    dup.html_safe!
  end
end