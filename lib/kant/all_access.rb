module Kant
  class AllAccess
    attr_reader :user

    def initialize(user = nil)
      @user = user
    end

    def can?(action, object)
      true
    end

    def accessible(action, scope, *rest)
      scope.all
    end
  end
end
