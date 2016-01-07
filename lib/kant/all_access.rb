module Kant
  class AllAccess
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def can?(action, object)
      true
    end

    def accessible(action, scope)
      scope.all
    end
  end
end
