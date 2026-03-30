# frozen_string_literal: true

module BusinessCentral
  module Object
    class Base
      using Refinements::Strings

      attr_reader :client

      def initialize(client, **args)
        @client = client
        @object_path = args.fetch(
          :object_path,
          [
            {
              path: 'companies',
              id: args.fetch(:company_id, client.default_company_id)
            },
            {
              path: args.fetch(:object_name, '').to_s.to_camel_case,
              id: args.fetch(:id, nil)
            }
          ]
        ).freeze
      end

      def find_all(**query_options)
        Request.get(@client, build_url(**query_options))
      end
      alias all find_all

      def find_by_id(id, **query_options)
        validate_id!(id)
        Request.get(@client, build_url(object_id: id, **query_options))
      end
      alias find find_by_id

      def where(query = '', *values, **query_options)
        filter = FilterQuery.sanitize(query, values)
        Request.get(@client, build_url(filter:, **query_options))
      end

      def create(params = {})
        Request.post(@client, build_url, params)
      end

      def update(id, params = {}, etag: nil)
        validate_id!(id)
        raise ArgumentError, 'params must be a Hash' unless params.is_a?(Hash)

        unless etag
          object = find_by_id(id)
          etag = object[:etag]
        end
        Request.patch(@client, build_url(object_id: id), etag, params)
      end

      def destroy(id, etag: nil)
        validate_id!(id)
        unless etag
          object = find_by_id(id)
          etag = object[:etag]
        end
        Request.delete(@client, build_url(object_id: id), etag)
      end
      alias delete destroy

      def method_missing(object_name, **params)
        log_unknown_entity(object_name)

        new_path = @object_path + [{
          path: object_name.to_s.to_camel_case,
          id: params.fetch(:id, nil)
        }]

        if BusinessCentral::Object.const_defined?(object_name.to_s.to_class_sym)
          klass = BusinessCentral::Object.const_get(object_name.to_s.to_class_sym)
          return klass.new(client, **params, object_path: new_path)
        end

        self.class.new(client, object_path: new_path)
      end

      def respond_to_missing?(object_name, _include_all = false)
        KNOWN_BC_ENTITIES.include?(object_name.to_s) ||
          BusinessCentral::Object.const_defined?(object_name.to_s.to_class_sym) ||
          super
      end

      private

      def validate_id!(id)
        raise ArgumentError, 'id cannot be nil' if id.nil?
        raise ArgumentError, 'id cannot be blank' if id.to_s.strip.empty?
      end

      def log_unknown_entity(object_name)
        return if KNOWN_BC_ENTITIES.include?(object_name.to_s)
        return unless @client.respond_to?(:logger)

        @client.logger.warn do
          "BC API: Accessing unregistered entity '#{object_name}'. This may be a typo."
        end
      end

      def build_url(object_id: '', filter: '', **query_options)
        URLBuilder.new(
          base_url: client.url,
          object_path: @object_path,
          object_id:,
          filter:,
          **query_options
        ).build
      end
    end
  end
end
