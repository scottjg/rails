module ActionView
  module Compilable
    def render(context, local_assigns = {}, &block)
      render_symbol = ['_run', extension, method_segment].compact.join('_')
      if local_assigns && local_assigns.any?
        render_symbol << "_locals_#{local_assigns.keys.map { |k| k.to_s }.sort.join('_')}"
      end
      render_symbol = render_symbol.to_sym

      if !Base::CompiledTemplates.method_defined?(render_symbol) || recompile?
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

      context.send(render_symbol, local_assigns, &block)
    end
  end
end
