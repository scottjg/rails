class Object
  # An object is blank if it's false, empty, or a whitespace string.
  # For example, "", "   ", +nil+, [], and {} are blank.
  #
  # This simplifies
  #
  #   if !address.nil? && !address.empty?
  #
  # to
  #
  #   if !address.blank?
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  # An object is present if it's not blank.
  def present?
    !blank?
  end

  # The nonblank? method is analogous to Ruby's Numeric#nonzero?[http://ruby-doc.org/core/classes/Numeric.html#M000186] method.
  #
  # Returns object unless it's #blank?(), in which case it returns nil:
  # object.nonblank? is equivalent to (object.blank? : nil : object).
  #
  # This is handy for any representation of objects where blank is the same
  # as not present at all.  For example, this simplifies a common check for
  # HTTP POST/query parameters:
  #
  #   state   = params[:state]   unless params[:state].blank?
  #   country = params[:country] unless params[:country].blank?
  #   region  = state || country || 'US'
  #
  # becomes
  #
  #   region = params[:state].nonblank? || params[:country].nonblank? || 'US'
  #
  # In general, nonblank? can be used any time you want to map empty? or false
  # to nil:
  #
  #   options = { :html => { :style => 'margin: 10;' } }
  #   other_options = options.except(:html).nonblank?
  #   => nil
  def nonblank?
    self unless blank?
  end
end

class NilClass #:nodoc:
  def blank?
    true
  end
end

class FalseClass #:nodoc:
  def blank?
    true
  end
end

class TrueClass #:nodoc:
  def blank?
    false
  end
end

class Array #:nodoc:
  alias_method :blank?, :empty?
end

class Hash #:nodoc:
  alias_method :blank?, :empty?
end

class String #:nodoc:
  def blank?
    self !~ /\S/
  end
end

class Numeric #:nodoc:
  def blank?
    false
  end
end
