module ActionDispatch
  class RemoteIp
    class IpSpoofAttackError < StandardError ; end

    # IP addresses that are "trusted proxies" that can be stripped from
    # the comma-delimited list in the X-Forwarded-For header. See also:
    # http://en.wikipedia.org/wiki/Private_network#Private_IPv4_address_spaces
    # http://en.wikipedia.org/wiki/Private_network#Private_IPv6_addresses.
    TRUSTED_PROXIES = %r{
      ^127\.0\.0\.1$                | # localhost
      ^::1$                         | # localhost
      ^fc00:                        | # private IP range fc00
      ^(10                          | # private IP range 10.x.x.x
        172\.(1[6-9]|2[0-9]|3[0-1]) | # private IP range 172.16.0.0 .. 172.31.255.255
        192\.168                    | # private IP range 192.168.x.x
       )\.
    }x

    attr_reader :check_ip, :proxies, :last_ip

    def initialize(app, check_ip_spoofing = true, custom_proxies = nil, last_forwarded_ip = true)
      @app = app
      @check_ip = check_ip_spoofing
      @last_ip = last_forwarded_ip
      @proxies = case custom_proxies
        when Regexp
          custom_proxies
        when nil
          TRUSTED_PROXIES
        else
          Regexp.union(TRUSTED_PROXIES, custom_proxies)
        end
    end

    def call(env)
      env["action_dispatch.remote_ip"] = GetIp.new(env, self)
      @app.call(env)
    end

    class GetIp

      # IP v4 and v6 (with compression) validation regexp
      # https://gist.github.com/1289635
      VALID_IP = %r{
        (^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})){3}$)                                                        | # ip v4
        (^(
        (([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})                                                                                                                   | # ip v6 not abbreviated
        (([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})                                                                                                                  | # ip v6 with double colon in the end
        (([0-9A-Fa-f]{1,4}:){5}:([0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4})                                                                                              | # - ip addresses v6
        (([0-9A-Fa-f]{1,4}:){4}:([0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4})                                                                                          | # - with
        (([0-9A-Fa-f]{1,4}:){3}:([0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4})                                                                                          | # - double colon
        (([0-9A-Fa-f]{1,4}:){2}:([0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4})                                                                                          | # - in the middle
        (([0-9A-Fa-f]{1,4}:){6} ((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3} (\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))                            | # ip v6 with compatible to v4
        (([0-9A-Fa-f]{1,4}:){1,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))                           | # ip v6 with compatible to v4
        (([0-9A-Fa-f]{1,4}:){1}:([0-9A-Fa-f]{1,4}:){0,4}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))     | # ip v6 with compatible to v4
        (([0-9A-Fa-f]{1,4}:){0,2}:([0-9A-Fa-f]{1,4}:){0,3}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))   | # ip v6 with compatible to v4
        (([0-9A-Fa-f]{1,4}:){0,3}:([0-9A-Fa-f]{1,4}:){0,2}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))   | # ip v6 with compatible to v4
        (([0-9A-Fa-f]{1,4}:){0,4}:([0-9A-Fa-f]{1,4}:){1}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))     | # ip v6 with compatible to v4
        (::([0-9A-Fa-f]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d) |(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))                         | # ip v6 with compatible to v4
        ([0-9A-Fa-f]{1,4}::([0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4})                                                                                               | # ip v6 with compatible to v4
        (::([0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})                                                                                                               | # ip v6 with double colon at the begining
        (([0-9A-Fa-f]{1,4}:){1,7}:)                                                                                                                                  # ip v6 without ending
        )$)
      }x

      def initialize(env, middleware)
        @env        = env
        @middleware = middleware
        @ip         = nil
      end

      # Determines originating IP address. REMOTE_ADDR is the standard
      # but will be wrong if the user is behind a proxy. Proxies will set
      # HTTP_CLIENT_IP and/or HTTP_X_FORWARDED_FOR, so we prioritize those.
      # HTTP_X_FORWARDED_FOR may be a comma-delimited list in the case of
      # multiple chained proxies. The last address which is not a known proxy
      # by default will be the originating IP according to this bug in Apache:
      # https://issues.apache.org/bugzilla/show_bug.cgi?id=50453 and behavior of
      # ruby servers: http://andre.arko.net/2011/12/26/repeated-headers-and-ruby-web-servers
      # In some exception cases it can be changed with config option
      # config.action_dispatch.last_forwarded_ip set to false.
      # It compiles to w3c spec:
      # http://www.w3.org/TR/2009/WD-ct-guidelines-20091006/#sec-additional-headers
      # See also http://en.wikipedia.org/wiki/X-Forwarded-For
      def calculate_ip
        client_ip     = @env['HTTP_CLIENT_IP']
        forwarded_ips = ips_from('HTTP_X_FORWARDED_FOR')
        forwarded_ips.reverse! if @middleware.last_ip
        remote_addrs  = ips_from('REMOTE_ADDR').reverse

        check_ip = client_ip && @middleware.check_ip
        if check_ip && !forwarded_ips.include?(client_ip)
          # We don't know which came from the proxy, and which from the user
          raise IpSpoofAttackError, "IP spoofing attack?!" \
            "HTTP_CLIENT_IP=#{@env['HTTP_CLIENT_IP'].inspect}" \
            "HTTP_X_FORWARDED_FOR=#{@env['HTTP_X_FORWARDED_FOR'].inspect}"
        end

        client_ips = [client_ip, forwarded_ips, remote_addrs].flatten.compact
        # Without a client IP, just return the first REMOTE_ADDR
        remove_proxies(client_ips).first || remote_addrs.first
      end

      def to_s
        @ip ||= calculate_ip
      end

    protected

      def ips_from(header)
        ips = @env[header] ? @env[header].strip.split(/[,\s]+/) : []
        ips.select{ |ip| ip =~ VALID_IP }
      end

      def remove_proxies(ips)
        ips.reject { |ip| ip =~ @middleware.proxies }
      end

    end

  end
end
