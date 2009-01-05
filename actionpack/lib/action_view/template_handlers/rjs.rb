module ActionView
  module TemplateHandlers
    module RJS
      include Compilable

      def compile
        "@template_format = :html;" +
        "controller.response.content_type ||= Mime::JS;" +
          "update_page do |page|;#{source}\nend"
      end
    end
  end
end
