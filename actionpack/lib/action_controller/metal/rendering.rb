module ActionController
  module Rendering
    extend ActiveSupport::Concern

    # Before processing, set the request formats in current controller formats.
    def process_action(*) #:nodoc:
      self.formats = request.formats.map(&:ref).compact
      super
    end

    # Check for double render errors and set the content_type after rendering.
    def render(*args) #:nodoc:
      puts "AC::Rendering#render args:#{args.to_s} "
      raise ::AbstractController::DoubleRenderError if self.response_body
      super
      self.content_type ||= rendered_format.to_s
      self.response_body
    end

    # Overwrite render_to_string because body can now be set to a rack body.
    def render_to_string(*args)
      puts "AC::Rendering#render-to_string (2) args:#{args.to_s} "
      if self.response_body = super
        string = ""
        self.response_body.each { |r| string << r }
        string
      end
    ensure
      self.response_body = nil
    end

    def render_to_body(*)
      super || " "
    end

    private

    # Normalize arguments by catching blocks and setting them on :update.
    def _normalize_args(action=nil, options={}, &blk) #:nodoc:
      puts "AC::Rendering#normalize-args (1) action:#{action} options:#{options}"
      options = super(action, options, &blk)
      puts "AC::Rendering#normalize-args (2) action:#{action} options:#{options}"
      options[:update] = blk if block_given?
      options
    end

    # Normalize both text and status options.
    def _normalize_options(options) #:nodoc:
      puts "AC::Rendering#normalize-opts (1) options:#{options}"
      if options.key?(:text) && options[:text].respond_to?(:to_text)
        options[:text] = options[:text].to_text
      end

      if options.delete(:nothing) || (options.key?(:text) && options[:text].nil?)
        options[:text] = " "
      end

      if options[:status]
        options[:status] = Rack::Utils.status_code(options[:status])
      end

      puts "AC::Rendering#normalize-opts (2) options:#{options}"
      s = super(options)
      puts "AC::Rendering#normalize-opts (3) options:#{s}"
      options
    end

    # Process controller specific options, as status, content-type and location.
    def _process_options(options) #:nodoc:
      status, content_type, location = options.values_at(:status, :content_type, :location)

      self.status = status if status
      self.content_type = content_type if content_type
      self.headers["Location"] = url_for(location) if location

      super
    end
  end
end
