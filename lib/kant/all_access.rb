module Kant
  class AllAccess
    def initialize(user)
    end

    def can?(action, object)
      true
    end

    def accessible(action, scope)
      scope.all
    end
  end
end
