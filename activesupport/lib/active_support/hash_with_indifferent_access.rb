ActiveSupport::HashWithIndifferentAccess =
  if Hash.method_defined?(:strhash)
    StrHash
  elsif Hash.method_defined?(:customize)
    require 'active_support/hash_with_indifferent_access/nobu'
    ActiveSupport::Hwia::Nobu
  else
    require 'active_support/hash_with_indifferent_access/ruby'
    ActiveSupport::Hwia::Ruby
  end

HashWithIndifferentAccess = ActiveSupport::HashWithIndifferentAccess
