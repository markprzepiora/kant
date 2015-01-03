module Kant
  module Resolvers
    module ActiveRecord
      private

      attr_reader :policies_module

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
