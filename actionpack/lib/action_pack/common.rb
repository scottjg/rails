module ActionPack
  module Common
    def partial_parts(name)
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
      prefix = segments[0..-2].join("/")
      prefix = prefix.blank? ? controller_path : prefix
      [path, formats, prefix]
    end
  end
end