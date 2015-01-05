module Kant
  module Resolvers
    module ActiveRecord
      private

      attr_reader :policies_module

      def resolve_object(object_or_class)
        klass =
          if object_or_class.is_a?(Class)
            object_or_class
          else
            object_or_class.class
          end

        resolve(klass.name)
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
