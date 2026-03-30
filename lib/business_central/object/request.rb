# frozen_string_literal: true

require 'openssl'

module BusinessCentral
  module Object
    class Request
      using Refinements::Strings

      HTTP_METHODS = {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
        patch: Net::HTTP::Patch,
        delete: Net::HTTP::Delete
      }.freeze

      SSL_OPTIONS = {
        use_ssl: true,
        verify_mode: OpenSSL::SSL::VERIFY_PEER,
        min_version: :TLS1_2
      }.freeze
      class << self
        def get(client, url)
          request(:get, client, url)
        end

        def post(client, url, params)
          request(:post, client, url, params:)
        end

        def patch(client, url, etag, params)
          request(:patch, client, url, etag:, params:)
        end

        def delete(client, url, etag)
          request(:delete, client, url, etag:)
        end

        def convert(request = {})
          result = {}
          request.each do |key, value|
            result[key.to_s.to_camel_case] = value if key.is_a? Symbol
            result[key.to_s] = value if key.is_a? String
          end

          result.to_json
        end

        def request(method, client, url, etag: '', params: {}, &block)
          http_class = HTTP_METHODS[method]
          raise ArgumentError, "Unsupported HTTP method: #{method}" unless http_class

          handle_response do
            uri = URI(url)
            req = build_request(http_class, uri, method, etag, params, &block)
            apply_auth(req, client)
            execute(uri, client, req)
          end
        end
        alias call request

        private

        def build_request(http_class, uri, method, etag, params)
          req = http_class.new(uri)
          req['If-Match'] = etag unless etag.to_s.strip.empty?
          req['Accept'] = 'application/json'

          if block_given?
            yield(req)
          else
            req['Content-Type'] = 'application/json'
            req.body = convert(params) if %i[post patch].include?(method)
          end

          req
        end

        def apply_auth(req, client)
          if client.access_token
            req['Authorization'] = "Bearer #{client.access_token.token}"
          else
            req.basic_auth(client.username, client.password)
          end
        end

        def execute(uri, client, req)
          options = SSL_OPTIONS.merge(
            open_timeout: client.open_timeout,
            read_timeout: client.read_timeout
          )
          Net::HTTP.start(uri.host, uri.port, options) do |http|
            if client.debug
              http.set_debug_output(
                FilteredDebugOutput.new(client.debug_output)
              )
            end
            http.request(req)
          end
        end

        def handle_response
          raw = yield
          response = Response.new(raw.read_body.to_s).results
          status = raw.code.to_i

          return response if Response.success?(status)
          return true if Response.success_no_content?(status)

          raise_status_error(status, response)
        end

        def raise_status_error(status, response)
          raise UnauthorizedException if Response.unauthorized?(status)
          raise NotFoundException if Response.not_found?(status)

          raise_api_error(status, response)
        end

        def raise_api_error(status, response)
          error = response&.fetch(:error, nil)
          if error
            raise CompanyNotFoundException if error[:code] == 'Internal_CompanyNotFound'
            raise ApiException, "#{status} - #{error[:code]} #{error[:message]}"
          end

          raise ApiException, "#{status} - API call failed"
        end
      end
    end
  end
end
