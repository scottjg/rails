# encoding: utf-8

module ActionView
  # NOTE: The template that this mixin is being included into is frozen
  # so you cannot set or modify any instance variables
  module Renderable #:nodoc:
    extend ActiveSupport::Memoizable

    def filename
      'compiled-template'
    end

    def handler
      Template.handler_class_for_extension(extension)
    end
    memoize :handler

    def compiled_source
      handler.call(self)
    end

    def method_name_without_locals
      ['_run', extension, method_segment].compact.join('_')
    end
    memoize :method_name_without_locals

    def render(view, local_assigns = {})
      compile(local_assigns)

      view.with_template self do
        view.send(:_evaluate_assigns_and_ivars)
        view.send(:_set_controller_content_type, mime_type) if respond_to?(:mime_type)

        view.send(method_name(local_assigns), local_assigns) do |*names|
          ivar = :@_proc_for_layout
          if !view.instance_variable_defined?(:"@content_for_#{names.first}") && view.instance_variable_defined?(ivar) && (proc = view.instance_variable_get(ivar))
            view.capture(*names, &proc)
          elsif view.instance_variable_defined?(ivar = :"@content_for_#{names.first || :layout}")
            res = view.instance_variable_get(ivar)
            res.respond_to?(:force_encoding) ? res.force_encoding(Encoding::UTF_8) : res
          end
        end
      end
    end

    def method_name(local_assigns)
      if local_assigns && local_assigns.any?
        method_name = method_name_without_locals.dup
        method_name << "_locals_#{local_assigns.keys.map { |k| k.to_s }.sort.join('_')}"
      else
        method_name = method_name_without_locals
      end
      method_name.to_sym
    end

    private
      # Compile and evaluate the template's code (if necessary)
      def compile(local_assigns)
        render_symbol = method_name(local_assigns)

        if !Base::CompiledTemplates.method_defined?(render_symbol) || recompile?
          compile!(render_symbol, local_assigns)
        end
      end

      def compile!(render_symbol, local_assigns)
        locals_code = local_assigns.keys.map { |key| "#{key} = local_assigns[:#{key}];" }.join

        source = <<-end_src
          def #{render_symbol}(local_assigns)
            old_output_buffer = output_buffer;#{locals_code};#{compiled_source.respond_to?(:force_encoding) ? compiled_source.force_encoding(Encoding::UTF_8) : compiled_source}
          ensure
            self.output_buffer = old_output_buffer
          end
        end_src

        # Workaround for erb
        source.force_encoding('utf-8') if '1.9'.respond_to?(:force_encoding)
        begin
          ActionView::Base::CompiledTemplates.module_eval(source, filename, 0)
        rescue Errno::ENOENT => e
          raise e # Missing template file, re-raise for Base to rescue
        rescue Exception => e # errors from template code
          if logger = defined?(ActionController) && Base.logger
            logger.debug "ERROR: compiling #{render_symbol} RAISED #{e}"
            logger.debug "Function body: #{source}"
            logger.debug "Backtrace: #{e.backtrace.join("\n")}"
          end

          raise ActionView::TemplateError.new(self, {}, e)
        end
      end

      def recompile?
        false
      end
  end
end
