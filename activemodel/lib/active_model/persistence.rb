module ActiveModel
  ##
  # This module implements no-op versions of the methods an extending framework
  # needs in order to implement persistence.
  # 
  # ActiveModel::Persistence is here to provide blank implementations of these methods
  # for the benefit of other modules which depend on them (e.g. ActiveModel::Callbacks).
  #
  module Persistence
    def create_or_update; end
  end
end