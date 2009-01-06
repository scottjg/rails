module ActionPack
  module Common
    def partial_parts(name, options)
      segments = name.split("/")
      parts = segments.pop.split(".")

      case parts.size
      when 1
        parts
      when 2, 3
        extension = parts.delete_at(1).to_sym
        if formats.include?(extension)
          self.formats.replace [extension]
        end
        parts.pop if parts.size == 2
      end
      
      path = parts.join(".")
      prefix = segments[0..-1].join("/")
      prefix = prefix.blank? ? controller_path : prefix
      parts = [path, formats, prefix]
      parts.push options[:object] || true
    end
  end
end