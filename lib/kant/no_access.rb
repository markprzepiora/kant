module Kant
  class NoAccess
    def initialize(user)
    end

    def can?(action, object)
      false
    end

    def accessible(action, scope)
      scope.none
    end
  end
end
