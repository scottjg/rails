module ActionPack #:nodoc:
  module VERSION #:nodoc:
    MAJOR = 3
    MINOR = 2
    TINY  = 0 #"pre" fixed to work with erubis 

    STRING = [MAJOR, MINOR, TINY].join('.')
  end
end
