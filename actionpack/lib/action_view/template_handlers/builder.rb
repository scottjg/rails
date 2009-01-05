require 'builder'

module ActionView
  module TemplateHandlers
    module Builder
      include Compilable

      def compile
        "_set_controller_content_type(Mime::XML);" +
          "xml = ::Builder::XmlMarkup.new(:indent => 2);" +
          "self.output_buffer = xml.target!;" +
          source +
          ";xml.target!;"
      end
    end
  end
end
