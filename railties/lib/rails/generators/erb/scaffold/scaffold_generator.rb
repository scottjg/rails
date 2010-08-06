require 'rails/generators/erb'
require 'rails/generators/resource_helpers'

module Erb
  module Generators
    class ScaffoldGenerator < Base
      include Rails::Generators::ResourceHelpers

      argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
      class_option :add_views, :type => :array, :default => [], :banner => "index _form etc", :desc => "add custom views/templates"
      class_option :skip_views, :type => :array, :default => [], :banner => "index _form etc", :desc => "skip views/templates"

      def create_root_folder
        empty_directory File.join("app/views", controller_file_path)
      end

      def copy_view_files
        available_views.each do |view|
          filename = filename_with_extensions(view)
          template filename, File.join("app/views", controller_file_path, filename)
        end
      end

    protected

      def available_views
        ( %w(index edit show new _form) | options[:add_views] ) - options[:skip_views]
      end

    end
  end
end
