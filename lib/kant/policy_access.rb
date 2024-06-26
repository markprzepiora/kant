require 'kant/resolvers/active_record'

module Kant
  class PolicyAccess
    include Kant::Resolvers::ActiveRecord

    attr_accessor :user

    def initialize(user, policies_module: nil)
      @user = user
      @policies_module = policies_module || Kernel
    end

    # Delegates to an appropriate Policy module. For example,
    #
    #   Ability.new(user).can?(:read, Foo.first)
    #
    # will return
    #
    #   FooPolicy.can_read?(Foo.first, user)
    def can?(action, object)
      method_eh     = "can_#{action}?"
      abilities     = resolve_object(object)
      _scope_method = scope_method(abilities, action)
      model_class   = object.class

      if abilities.respond_to?(method_eh)
        abilities.send(method_eh, object, user)
      elsif _scope_method && object.id
        abilities.send(_scope_method, model_class, user).where(id: object.id).any?
      else
        false
      end
    end

    # Example:
    #
    #   ability.accessible(:read, Content)
    #   # => a Content scope
    def accessible(action, scope, *rest, **kwargs)
      abilities = resolve_scope(scope)
      _scope_method = scope_method(abilities, action)

      if _scope_method
        abilities.send(_scope_method, scope, user, *rest, **kwargs)
      else
        scope.none
      end
    end

    private

    def scope_method(abilities, action)
      regular_name = "#{action}able"
      alternate_name = begin
        first, *rest = action.to_s.split('_')
        "#{first}able_#{rest.join('_')}"
      end

      if abilities.respond_to?(regular_name)
        regular_name
      elsif abilities.respond_to?(alternate_name)
        alternate_name
      else
        nil
      end
    end
  end
end
