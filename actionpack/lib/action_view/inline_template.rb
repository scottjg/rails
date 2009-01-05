module ActionView #:nodoc:
  class InlineTemplate #:nodoc:
    attr_reader :source, :extension, :method_segment

    def initialize(source, type = nil)
      @source = source
      @extension = type
      @method_segment = "inline_#{@source.hash.abs}"
      extend Template.handler_class_for_extension(@extension)
    end

    private
      def filename
        'compiled-template'
      end

      # Always recompile inline templates
      def recompile?
        true
      end
  end
end
