module ActionView
  module Helpers
    module AjaxHelper
      include UrlHelper

      def remote_form_for(record_or_name_or_array, *args, &proc)
        options = args.extract_options!

        case record_or_name_or_array
        when String, Symbol
          object_name = record_or_name_or_array
        when Array
          object = record_or_name_or_array.last
          object_name = ActionController::RecordIdentifier.singular_class_name(object)
          apply_form_for_options!(record_or_name_or_array, options)
          args.unshift object
        else
          object      = record_or_name_or_array
          object_name = ActionController::RecordIdentifier.singular_class_name(record_or_name_or_array)
          apply_form_for_options!(object, options)
          args.unshift object
        end

        concat(form_remote_tag(options))
        fields_for(object_name, *(args << options), &proc)
        concat('</form>')
      end
      alias_method :form_remote_for, :remote_form_for

      def form_remote_tag(options = {}, &block)
        attributes = {}
        attributes.merge!(extract_remote_attributes!(options))
        attributes.merge!(options)

        url = attributes.delete(:url)
        form_tag(attributes.delete(:action) || url_for(url), attributes, &block)
      end

      def extract_remote_attributes!(options)
        attributes = options.delete(:html) || {}
        
        update = options.delete(:update)
        if update.is_a?(Hash)
          attributes["data-update-success"] = update[:success]
          attributes["data-update-failure"] = update[:failure]
        else
          attributes["data-update-success"] = update
        end

        attributes["data-update-position"] = options.delete(:position)
        attributes["data-method"]          = options.delete(:method)
        attributes["data-remote"]          = true

        attributes
      end

      def link_to_remote(name, url, options = {})
        attributes = {}
        attributes.merge!(extract_remote_attributes!(options))
        attributes.merge!(options)

        url = url_for(url) if url.is_a?(Hash)
        link_to(name, url, attributes)
      end
      
      def button_to_remote(name, options = {}, html_options = {})
        url = options.delete(:url)
        url = url_for(url) if url.is_a?(Hash)
        
        html_options.merge!(:type => "button", :value => name,
          :"data-url" => url)
        
        tag(:input, html_options)
      end

      def observe_field(name, options = {})
        if options[:url]
          options[:url] = options[:url].is_a?(Hash) ? url_for(options[:url]) : options[:url]
        end
        
        if options[:frequency]
          case options[:frequency]
            when 0
              options.delete(:frequency)
            else
              options[:frequency] = options[:frequency].to_i
          end
        end

        if options[:with]
          if options[:with] !~ /[\{=(.]/
            options[:with] = "'#{options[:with]}=' + encodeURIComponent(value)"
          else
            options[:with] ||= 'value' unless options[:function]
          end
        end

        if options[:function]
          statements = options[:function] # || remote_function(options) # TODO: Need to implement remote function - BR
          options[:function] = JSFunction.new(statements, "element", "value")
        end

        options[:name] = name

        <<-SCRIPT
        <script type="application/json" data-rails-type="observe_field">
        //<![CDATA[
          #{options.to_json}
        // ]]>
        </script>
        SCRIPT
      end

      module Rails2Compatibility
        def set_callbacks(options, html)
          [:complete, :failure, :success, :interactive, :loaded, :loading].each do |type|
            html["data-#{type}-code"]  = options.delete(type.to_sym)
          end

          options.each do |option, value|
            if option.is_a?(Integer)
              html["data-#{option}-code"] = options.delete(option)
            end
          end
        end
        
        def link_to_remote(name, url, options = nil)
          if !options && url.is_a?(Hash) && url.key?(:url)
            url, options = url.delete(:url), url
          end
          
          set_callbacks(options, options[:html] ||= {})
          
          super
        end
        
        def button_to_remote(name, options = {}, html_options = {})
          set_callbacks(options, html_options)
          super
        end
      end

      private

      # TODO: Move to javascript helpers - BR
      class JSFunction
        def initialize(statements, *arguments)
          @statements, @arguments = statements, arguments
        end

        def as_json(options = nil)
          "function(#{@arguments.join(", ")}) {#{@statements}}"
        end
      end

    end
  end
end