require "digest/md5"

module ActiveResource
  # Written by Eric Hodel <drbrain@segment7.net>
  # Copied and adapted from http://segment7.net/projects/ruby/snippets/digest_auth.rb
  #
  #  HTTP Digest Authentication
  module Digest
    @@nonce_count = -1

    CNONCE = ::Digest::MD5.hexdigest("%x" % (Time.now.to_i + rand(65535)))
    # CNONCE = ActiveSupport::SecureRandom.hex(32)

    def self.authenticate(uri, user, password, auth_header, method = :get, is_IIS = false)
      uri = URI.parse(uri) unless uri.kind_of?(URI)
      @@nonce_count += 1

      auth_header =~ /^(\w+) (.*)/
      raise ArgumentError, "Authentication method must be 'Digest', found #{$1}" unless $1 == "Digest"

      params = {}
      $2.gsub(/(\w+)="(.*?)"/) { params[$1] = $2 }

      a_1 = "#{user}:#{params['realm']}:#{password}"
      a_2 = "#{method.to_s.upcase}:#{uri.path}"
      request_digest = ''
      request_digest << ::Digest::MD5.hexdigest(a_1)
      request_digest << ':' << params["nonce"]
      request_digest << ':' << ("%08x" % @@nonce_count)
      request_digest << ':' << CNONCE
      request_digest << ':' << params["qop"]
      request_digest << ':' << ::Digest::MD5.hexdigest(a_2)

      header = ''
      header << "Digest username=\"#{user}\", "
      header << "realm=\"#{params["realm"]}\", "
      if is_IIS then
        header << "qop=\"#{params["qop"]}\", "
      else
        header << "qop=#{params["qop"]}, "
      end
      header << "uri=\"#{uri.path}\", "
      header << "nonce=\"#{params["nonce"]}\", "
      header << "nc=#{"%08x" % @@nonce_count}, "
      header << "cnonce=\"#{CNONCE}\", "
      header << "opaque=\"#{params["opaque"]}\", "
      header << "response=\"#{::Digest::MD5.hexdigest(request_digest)}\""

      return header
    end
  end
end
