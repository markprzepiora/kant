module Kant
  module Resolvers
    module ActiveRecord
      private

      def policies_module
        Kernel
      end

      def resolve_object(object)
        resolve(object.class.name)
      end

      def resolve_scope(scope)
        resolve(scope.all.model.name)
      end

      def resolve(name)
        policies_module.const_get("#{name}Policy")
      rescue NameError
        nil
      end
    end
  end
end
