class String
  def html_safe?
    defined?(@_rails_html_safe) && @_rails_html_safe
  end

  def mark_html_safe
    @_rails_html_safe = true
    self
  end
end