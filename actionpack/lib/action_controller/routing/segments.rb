module ActionController
  module Routing
    class Segment #:nodoc:
      RESERVED_PCHAR = ':@&=+$,;'
      SAFE_PCHAR = "#{URI::REGEXP::PATTERN::UNRESERVED}#{RESERVED_PCHAR}"
      UNSAFE_PCHAR = Regexp.new("[^#{SAFE_PCHAR}]", false, 'N').freeze

      # TODO: Convert :is_optional accessor to read only
      attr_accessor :is_optional
      alias_method :optional?, :is_optional

      def self.escape_path(value)
        value.nil? ? '' : URI.escape(value.to_s, UNSAFE_PCHAR)
      end

      def initialize
        @is_optional = false
      end

      def present?(values = nil)
        true
      end

      def number_of_captures
        Regexp.new(regexp_chunk).number_of_captures
      end

      def to_path(values = nil)
        self.class.escape_path(value)
      end

      def generate_path(prior_segments, values = {})
        if optional?
          if prior_segments.empty?
            to_path(values)
          else
            prior_segments.pop.generate_path(prior_segments, values)
          end
        else
          segments_to_path_if_optional_segments_have_values(prior_segments, values)
        end
      end

      def segments_to_path_if_optional_segments_have_values(prior_segments, values)
        if prior_segments.all? { |s| !s.optional? || s.present?(values) }
          "#{prior_segments.map { |s| s.to_path(values) }.join}#{to_path(values)}"
        end
      end

      # Recognition

      def match_extraction(next_capture)
        nil
      end

      # Warning

      # Returns true if this segment is optional? because of a default. If so, then
      # no warning will be emitted regarding this segment.
      def optionality_implied?
        false
      end
    end

    class StaticSegment < Segment #:nodoc:
      attr_reader :value, :raw
      alias_method :raw?, :raw

      def initialize(value = nil, options = {})
        super()
        @value = value
        @raw = options[:raw] if options.key?(:raw)
        @is_optional = options[:optional] if options.key?(:optional)
      end

      def to_path(values = nil)
        raw? ? value.to_s : super
      end

      def regexp_chunk
        chunk = Regexp.escape(value)
        optional? ? Regexp.optionalize(chunk) : chunk
      end

      def number_of_captures
        0
      end

      def build_pattern(pattern)
        escaped = Regexp.escape(value)
        if optional? && ! pattern.empty?
          "(?:#{Regexp.optionalize escaped}\\Z|#{escaped}#{Regexp.unoptionalize pattern})"
        elsif optional?
          Regexp.optionalize escaped
        else
          escaped + pattern
        end
      end

      def to_s
        value
      end
    end

    class DividerSegment < StaticSegment #:nodoc:
      def initialize(value = nil, options = {})
        super(value, {:raw => true, :optional => true}.merge(options))
      end

      def optionality_implied?
        true
      end
    end

    class DynamicSegment < Segment #:nodoc:
      attr_reader :key

      # TODO: Convert these accessors to read only
      attr_accessor :default, :regexp
      attr_reader :value_regexp

      def initialize(key = nil, options = {})
        super()

        @key = key
        @default = options[:default] if options.key?(:default)
        self.regexp = options[:regexp] if options.key?(:regexp)
        @is_optional = true if options[:optional] || options.key?(:default)
      end

      def regexp=(re)
        if @regexp = re
          @value_regexp = Regexp.new("\\A#{@regexp.to_s}\\Z")
        end
        re
      end

      def to_s
        ":#{key}"
      end

      def present?(values = {})
        !values[key].nil?
      end

      def extract_value(hash)
        (hash[key] && hash[key].to_param) || default
      end

      def matches?(value)
        if default
          !value_regexp || value_regexp =~ value
        elsif optional?
          value.nil? || !value_regexp || value_regexp =~ value
        else
          value && (!value_regexp || value_regexp =~ value)
        end
      end

      def to_path(values = {})
        self.class.escape_path(values[key])
      end

      def generate_path(prior_segments, values = {})
        if optional? && values[key] == default
          if prior_segments.empty?
            to_path(values)
          else
            prior_segments.pop.generate_path(prior_segments, values)
          end
        else
          segments_to_path_if_optional_segments_have_values(prior_segments, values)
        end
      end

      def regexp_chunk
        if regexp
          if regexp_has_modifiers?
            "(#{regexp.to_s})"
          else
            "(#{regexp.source})"
          end
        else
          "([^#{Routing::SEPARATORS.join}]+)"
        end
      end

      def number_of_captures
        if regexp
          regexp.number_of_captures + 1
        else
          1
        end
      end

      def build_pattern(pattern)
        pattern = "#{regexp_chunk}#{pattern}"
        optional? ? Regexp.optionalize(pattern) : pattern
      end

      def match_extraction(next_capture)
        # All non code-related keys (such as :id, :slug) are URI-unescaped as
        # path parameters.
        default_value = default ? default.inspect : nil
        %[
          value = if (m = match[#{next_capture}])
            URI.unescape(m)
          else
            #{default_value}
          end
          params[:#{key}] = value if value
        ]
      end

      def optionality_implied?
        [:action, :id].include? key
      end

      def regexp_has_modifiers?
        regexp.options & (Regexp::IGNORECASE | Regexp::EXTENDED) != 0
      end
    end

    class ControllerSegment < DynamicSegment #:nodoc:
      def to_path(values = {})
        values[key].to_s
      end

      # Make sure controller names like Admin/Content are correctly normalized to
      # admin/content
      def extract_value(hash)
        (hash[key] || default).to_s.downcase
      end

      def regexp_chunk
        possible_names = Routing.possible_controllers.collect { |name| Regexp.escape name }
        "(?i-:(#{(regexp || Regexp.union(*possible_names)).source}))"
      end

      def number_of_captures
        1
      end

      def match_extraction(next_capture)
        if default
          "params[:#{key}] = match[#{next_capture}] ? match[#{next_capture}].downcase : '#{default}'"
        else
          "params[:#{key}] = match[#{next_capture}].downcase if match[#{next_capture}]"
        end
      end
    end

    class PathSegment < DynamicSegment #:nodoc:
      def to_path(values = {})
        values[key].to_s
      end

      def extract_value(hash)
        if value = hash[key]
          value = value.split('/') if value.is_a?(String)
          Array(value).map { |p| self.class.escape_path(p.to_param) }.to_param
        else
          default
        end
      end

      def default
        ''
      end

      def default=(path)
        raise RoutingError, "paths cannot have non-empty default values" unless path.blank?
      end

      def match_extraction(next_capture)
        "params[:#{key}] = PathSegment::Result.new_escaped((match[#{next_capture}]#{" || " + default.inspect if default}).split('/'))#{" if match[" + next_capture + "]" if !default}"
      end

      def regexp_chunk
        regexp || "(.*)"
      end

      def number_of_captures
        regexp ? regexp.number_of_captures : 1
      end

      def optionality_implied?
        true
      end

      class Result < ::Array #:nodoc:
        def to_s() join '/' end
        def self.new_escaped(strings)
          new strings.collect {|str| URI.unescape str}
        end
      end
    end

    # The OptionalFormatSegment allows for any resource route to have an optional
    # :format, which decreases the amount of routes created by 50%.
    class OptionalFormatSegment < DynamicSegment
      def initialize(key = nil, options = {})
        super(:format, {:optional => true}.merge(options))
      end

      def to_path(values = {})
        ".#{super}"
      end

      def regexp_chunk
        '(\.[^/?\.]+)?'
      end

      def to_s
        '(.:format)?'
      end

      #the value should not include the period (.)
      def match_extraction(next_capture)
        %[
          if (m = match[#{next_capture}])
            params[:#{key}] = URI.unescape(m.from(1))
          end
        ]
      end
    end
  end
end
