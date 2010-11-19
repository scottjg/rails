# heavily based on Masao Mutoh's gettext String interpolation extension
# http://github.com/mutoh/gettext/blob/f6566738b981fe0952548c421042ad1e0cdfb31e/lib/gettext/core_ext/string.rb

# KeyError is raised by String#% when the string contains a named placeholder that is
# not contained in the given arguments hash. Ruby 1.9 defines and raises this exception
# natively. We define it to mimic Ruby 1.9's behaviour in Ruby 1.8.x
class KeyError < IndexError
  def initialize(message = nil)
    super(message || "key not found")
  end
end unless defined?(KeyError)

class String
  INTERPOLATION_PATTERN = Regexp.union(
    /%\{(\w+)\}/,                               # matches placeholders like "%{foo}"
    /%<(\w+)>(.*?\d*\.?\d*[bBdiouxXeEfgGcps])/  # matches placeholders like "%<foo>.d"
  )

  INTERPOLATION_PATTERN_WITH_ESCAPE = Regexp.union(
    /%%/,
    INTERPOLATION_PATTERN
  )

  alias :interpolate_without_ruby_19_syntax :%  # :nodoc:

  # Backports the Ruby 1.9 string interpolation syntax to Ruby 1.8.
  # See the Ruby 1.9 sprintf documentation for details.
  def %(args)
    if args.kind_of?(Hash)
      dup.gsub(INTERPOLATION_PATTERN_WITH_ESCAPE) do |match|
        if match == '%%'
          '%'
        else
          key = ($1 || $2).to_sym
          raise KeyError unless args.has_key?(key)
          $3 ? sprintf("%#{$3}", args[key]) : args[key]
        end
      end
    elsif self =~ INTERPOLATION_PATTERN
      raise ArgumentError.new('one hash required')
    else
      result = gsub(/%([{<])/, '%%\1')
      result.send :'interpolate_without_ruby_19_syntax', args
    end
  end
  # the following check can be removed once we can be sure I18n does not ship
  # with the same patch anymore
end unless ''.respond_to?(:interpolate_without_ruby_19_syntax)
