# frozen_string_literal: true

module BusinessCentral
  module Object
    class Response
      using Refinements::Strings

      class << self
        def success?(status)
          [200, 201].include?(status)
        end

        def success_no_content?(status)
          status == 204
        end

        def bad_request?(status)
          status == 400
        end

        def unauthorized?(status)
          status == 401
        end

        def forbidden?(status)
          status == 403
        end

        def not_found?(status)
          status == 404
        end

        def conflict?(status)
          status == 409
        end

        def unprocessable?(status)
          status == 422
        end

        def rate_limited?(status)
          status == 429
        end

        def server_error?(status)
          status >= 500
        end
      end

      attr_reader :results

      def initialize(response)
        @results = nil
        return if response.blank?

        @response = JSON.parse(response)
        @response = @response['value'] if @response.is_a?(Hash) && @response.key?('value')
        process
      rescue JSON::ParserError => e
        raise ApiException, "Failed to parse API response: #{e.message}"
      end

      private

      def process
        case @response
        when String
          @results = @response
        when Array
          @results = @response.map { |data| convert(data) }
        when Hash
          @results = convert(@response)
        end
      end

      def convert(data)
        result = {}
        data.each do |key, value|
          if key == '@odata.etag'
            result[:etag] = value
          elsif key == '@odata.context'
            result[:context] = value
          elsif key == '@odata.nextLink'
            result[:next_link] = value
          elsif value.is_a?(Hash)
            result[key.to_snake_case.to_sym] = convert(value)
          else
            result[key.to_snake_case.to_sym] = value
          end
        end

        result
      end
    end
  end
end
