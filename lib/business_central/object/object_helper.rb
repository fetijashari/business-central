# frozen_string_literal: true

module BusinessCentral
  module Object
    module ObjectHelper
      using Refinements::Strings

      def method_missing(object_name, **params)
        log_unknown_entity(object_name)

        if BusinessCentral::Object.const_defined?(object_name.to_s.to_class_sym)
          klass = BusinessCentral::Object.const_get(object_name.to_s.to_class_sym)
          klass.new(self, **params)
        else
          BusinessCentral::Object::Base.new(self, **params.merge!({ object_name: }))
        end
      end

      def respond_to_missing?(object_name, _include_all = false)
        KNOWN_BC_ENTITIES.include?(object_name.to_s) ||
          BusinessCentral::Object.const_defined?(object_name.to_s.to_class_sym) ||
          super
      end

      private

      def log_unknown_entity(object_name)
        return if KNOWN_BC_ENTITIES.include?(object_name.to_s)
        return unless respond_to?(:logger)

        logger.warn do
          "BC API: Accessing unregistered entity '#{object_name}'. This may be a typo."
        end
      end
    end
  end
end
