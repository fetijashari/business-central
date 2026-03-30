# frozen_string_literal: true

module BusinessCentral
  module Object
    class URLBuilder
      using Refinements::Strings

      extend URLHelper

      QUERY_PARAM_MAP = {
        filter: '$filter',
        top: '$top',
        skip: '$skip',
        order_by: '$orderby',
        select: '$select',
        expand: '$expand'
      }.freeze

      class << self
        def sanitize(query = '', values = [])
          return encode_url_params(query) if values.empty?

          query = replace_template_with_value(query, values)
          encode_url_object(query)
        end
      end

      def initialize(base_url:, object_path: [], object_id: '', object_code: '', **options)
        @base_url = base_url.to_s
        @object_path = object_path || []
        @object_id = object_id.to_s
        @object_code = object_code.to_s
        @query_values = extract_query_values(options)
      end

      def build
        url = @base_url
        url += build_parent_path
        url += build_child_path
        url += build_query_string
        url
      end

      private

      def extract_query_values(options)
        {
          filter: options[:filter].to_s,
          top: options[:top],
          skip: options[:skip],
          order_by: options[:order_by],
          select: options[:select],
          expand: options[:expand]
        }
      end

      def build_parent_path
        return '' if @object_path.empty?

        @object_path.map do |parent|
          if parent[:id].nil?
            "/#{parent[:path]}"
          else
            "/#{parent[:path]}(#{parent[:id]})"
          end
        end.join
      end

      def build_child_path
        url = ''
        url += "(#{@object_id})" if @object_id.present?
        url += "('#{odata_encode(@object_code)}')" if @object_code.present?
        url
      end

      def build_query_string
        params = QUERY_PARAM_MAP.filter_map do |key, odata_key|
          value = @query_values[key]
          next if value.nil? || (value.is_a?(String) && value.empty?)

          "#{odata_key}=#{value}"
        end
        return '' if params.empty?

        "?#{params.join('&')}"
      end
    end
  end
end
