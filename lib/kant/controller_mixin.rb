require 'kant/access_denied'

module Kant
  module ControllerMixin
    # By default, Kant expects an AccessControl class to exist. Override this
    # method if you need more complicated logic here. A typical implementation
    # might be:
    #
    #   def current_access_control
    #     @current_access_control ||=
    #       if !current_user
    #         Kant::NoAccess.new(nil)
    #       elsif current_user.admin?
    #         Kant::AllAccess.new(current_user)
    #       else
    #         AccessControl.new(current_user)
    #       end
    #   end
    def current_access_control
      @current_access_control ||= AccessControl.new(current_user)
    end

    private

    # Delegates to current_access_control
    def can?(*args)
      current_access_control.can?(*args)
    end

    # Delegates to current_access_control
    def accessible(*args)
      current_access_control.accessible(*args)
    end

    # If `can?(action, object)` is true, then this is a no-op. If on the other
    # hand that value is false, this raises a Kant::AccessDenied exception.
    def authorize!(action, object)
      if can?(action, object)
        true
      else
        raise Kant::AccessDenied, "You are not permitted to #{action} this record."
      end
    end
  end
end
