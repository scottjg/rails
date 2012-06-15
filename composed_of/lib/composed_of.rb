require 'active_support/lazy_load_hooks'
require 'composed_of/version'

ActiveSupport.on_load(:active_record) do
  require 'composed_of/aggregations'
end
