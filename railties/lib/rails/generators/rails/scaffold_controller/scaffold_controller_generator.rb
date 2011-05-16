require 'rails/generators/resource_helpers'

module Rails
  module Generators
    class ScaffoldControllerGenerator < NamedBase
      include ResourceHelpers

      check_class_collision :suffix => "Controller"

      class_option :orm, :banner => "NAME", :type => :string, :required => true,
                         :desc => "ORM to generate the controller for"

      class_option :skip_respond_to, :type => :boolean, :default => false,
                                     :desc => "Skip generating respond_to blocks"

      def create_controller_files
        template 'controller.rb', File.join('app/controllers', class_path, "#{controller_file_name}_controller.rb")
      end

      def skip_respond_to
        options[:skip_respond_to]
      end

      hook_for :template_engine, :test_framework, :as => :scaffold

      # Invoke the helper using the controller name (pluralized)
      hook_for :helper, :as => :scaffold do |invoked|
        invoke invoked, [ controller_name ]
      end
    end
  end
end
