module Kant
  module Resolvers
    module ActiveRecord
      private

      def resolve_object(object)
        resolve(object.class.name)
      end

      def resolve_scope(scope)
        resolve(scope.all.model.name)
      end

      def resolve(name)
        "#{name}Policy".constantize
      rescue NameError
        nil
      end
    end
  end
end
