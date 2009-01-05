module ActionView
  module Compilable
    def render(context, local_assigns = {}, &block)
      render_symbol = method_name(local_assigns)
      if !Base::CompiledTemplates.method_defined?(render_symbol) || recompile?
        compile!(render_symbol, local_assigns)
      end
      context.send(render_symbol, local_assigns, &block)
    end

    private
      # TODO: Merge with render method
      def compile!(render_symbol, local_assigns)
        locals_code = local_assigns.keys.map { |key| "#{key} = local_assigns[:#{key}];" }.join

        source = <<-end_src
          def #{render_symbol}(local_assigns)
            old_output_buffer = output_buffer;#{locals_code};#{compile}
          ensure
            self.output_buffer = old_output_buffer
          end
        end_src

        begin
          ActionView::Base::CompiledTemplates.module_eval(source, filename, 0)
        rescue Exception => e # errors from template code
          if logger = defined?(ActionController) && Base.logger
            logger.debug "ERROR: compiling #{render_symbol} RAISED #{e}"
            logger.debug "Function body: #{source}"
            logger.debug "Backtrace: #{e.backtrace.join("\n")}"
          end

          raise ActionView::TemplateError.new(self, {}, e)
        end
      end

      # TODO: Merge with render method
      def method_name(local_assigns)
        method_name = ['_run', extension, method_segment].compact.join('_')
        if local_assigns && local_assigns.any?
          method_name << "_locals_#{local_assigns.keys.map { |k| k.to_s }.sort.join('_')}"
        end
        method_name.to_sym
      end
  end
end
