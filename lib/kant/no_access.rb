module Kant
  class NoAccess
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def can?(action, object)
      false
    end

    def accessible(action, scope)
      scope.none
    end
  end
end
