module Rails
  module VERSION #:nodoc:
    MAJOR = 2 unless defined?(MAJOR)
    MINOR = 3 unless defined?(MINOR)
    TINY  = 9 unless defined?(TINY)

    STRING = [MAJOR, MINOR, TINY].join('.') unless defined?(STRING)
  end
end
