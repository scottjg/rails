active_support_path = File.expand_path('../../../active_support/lib', __FILE__)
$:.unshift(active_support_path) if File.directory?(active_support_path) && !$:.include?(active_support_path)

require 'action_pack'
require 'active_support/concern'
require 'active_support/ruby/shim'
require 'active_support/dependencies/autoload'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/module/attr_internal'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/anonymous'
require 'active_support/i18n'

module AbstractController
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Callbacks
  autoload :Collector
  autoload :Helpers
  autoload :Layouts
  autoload :Logger
  autoload :Rendering
  autoload :Translation
  autoload :AssetPaths
  autoload :ViewPaths
  autoload :UrlFor
end
