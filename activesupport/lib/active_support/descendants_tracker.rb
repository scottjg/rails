module ActiveSupport
  # This module provides an internal implementation to track descendants
  # which is faster than iterating through ObjectSpace.
  module DescendantsTracker
    # 全局Hash，key为类，value为数组，表示key类的直接后代类
    @@direct_descendants = Hash.new { |h, k| h[k] = [] }

    # 模块方法，返回klass类的直接后代类
    def self.direct_descendants(klass)
      @@direct_descendants[klass]
    end

    # 模块方法，返回klass类的所有后代类
    def self.descendants(klass)
      @@direct_descendants[klass].inject([]) do |descendants, _klass|
        descendants << _klass
        descendants.concat _klass.descendants
      end
    end

    # 模块方法
    def self.clear
      if defined? ActiveSupport::Dependencies
        @@direct_descendants.each do |klass, descendants|
          if ActiveSupport::Dependencies.autoloaded?(klass)
            @@direct_descendants.delete(klass)
          else
            descendants.reject! { |v| ActiveSupport::Dependencies.autoloaded?(v) }
          end
        end
      else
        @@direct_descendants.clear
      end
    end

    # 继承，将base加入到direct_decendants列表中，self表示混入了DescendantsTracker的类
    def inherited(base)
      self.direct_descendants << base
      super
    end

    # 返回当前类的直接后代类
    def direct_descendants
      DescendantsTracker.direct_descendants(self)
    end

    # 返回当前类的所有后代类
    def descendants
      DescendantsTracker.descendants(self)
    end
  end
end
