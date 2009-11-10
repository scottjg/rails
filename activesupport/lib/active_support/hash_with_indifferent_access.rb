require 'active_support/hash_with_indifferent_access/nobu'
require 'active_support/hash_with_indifferent_access/ruby'

ActiveSupport::HashWithIndifferentAccess =
  if Hash.method_defined?(:customize)
    ActiveSupport::Hwia::Nobu
  else
    ActiveSupport::Hwia::Ruby
  end

HashWithIndifferentAccess = ActiveSupport::HashWithIndifferentAccess
