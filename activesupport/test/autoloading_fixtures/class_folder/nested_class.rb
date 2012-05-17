class ClassFolder
  class NestedClass
    class << self
      def use_sibling_class
        SiblingClass.new
      end
      def use_class_folder_subclass
        ClassFolderSubclass.new
      end
    end
  end

  class SiblingClass
  end
end
