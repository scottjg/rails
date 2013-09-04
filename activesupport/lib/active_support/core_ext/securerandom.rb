module SecureRandom
  UUID_DNS_NAMESPACE  = "k\xA7\xB8\x10\x9D\xAD\x11\xD1\x80\xB4\x00\xC0O\xD40\xC8" #:nodoc:
  UUID_URL_NAMESPACE  = "k\xA7\xB8\x11\x9D\xAD\x11\xD1\x80\xB4\x00\xC0O\xD40\xC8" #:nodoc:
  UUID_OID_NAMESPACE  = "k\xA7\xB8\x12\x9D\xAD\x11\xD1\x80\xB4\x00\xC0O\xD40\xC8" #:nodoc:
  UUID_X500_NAMESPACE = "k\xA7\xB8\x14\x9D\xAD\x11\xD1\x80\xB4\x00\xC0O\xD40\xC8" #:nodoc:
  
  # ::uuid generates a v5 non-random UUID (Universally Unique IDentifier)
  #
  #   p SecureRandom.uuid_from_hash(Digest::MD5, SecureRandom::UUID_DNS_NAMESPACE, 'www.widgets.com') #=> "3d813cbb-47fb-32ba-91df-831e1593ac29"
  #   p SecureRandom.uuid_from_hash(Digest::MD5, SecureRandom::UUID_URL_NAMESPACE, 'http://www.widgets.com') #=> "86df55fb-428e-3843-8583-ba3c05f290bc"
  #   p SecureRandom.uuid_from_hash(Digest::SHA1, SecureRandom::UUID_OID_NAMESPACE, '1.2.3') #=> "42d5e23b-3a02-5135-9135-52d1102f1f00"
  #   p SecureRandom.uuid_from_hash(Digest::SHA1, SecureRandom::UUID_X500_NAMESPACE, 'cn=John Doe, ou=People, o=Acme, c=US') #=> "fd5b2ddf-bcfe-58b6-90d6-db50f74db527"
  #
  # Using Digest::MD5 generates version 3 UUIDs; Digest::SHA1 generates version 5 UUIDs.
  # ::uuid_from_hash always generates the same UUID for a given name and namespace combination.
  #
  # See RFC 4122 for details of UUID.
  def self.uuid_from_hash(hash_class, uuid_namespace, name)
    if hash_class == Digest::MD5
      version = 3
    elsif hash_class == Digest::SHA1
      version = 5
    else
      raise ArgumentError, "Expected Digest::SHA1 or Digest::MD5, got #{hash_class.name}."
    end

    hash = hash_class.new
    hash.update(uuid_namespace)
    hash.update(name)

    ary = hash.digest.unpack('NnnnnN')
    ary[2] = (ary[2] & 0x0FFF) | (version << 12)
    ary[3] = (ary[3] & 0x3FFF) | 0x8000

    "%08x-%04x-%04x-%04x-%04x%08x" % ary
  end

  # ::uuid_v3 is a convenience method for ::uuid_from_hash using Digest::MD5.
  def self.uuid_v3(uuid_namespace, name)
    self.uuid_from_hash(Digest::MD5, uuid_namespace, name)
  end

  # ::uuid_v5 is a convenience method for ::uuid_from_hash using Digest::SHA1.
  def self.uuid_v5(uuid_namespace, name)
    self.uuid_from_hash(Digest::SHA1, uuid_namespace, name)
  end

  class << self
    # ::uuid_v4 is an alias for ::uuid.
    alias_method :uuid_v4, :uuid
  end
end
