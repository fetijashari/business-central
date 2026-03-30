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

          logged_request(method, url, client) do
            request_with_retry(client) do
              perform(http_class, client, url, method, { etag:, params: }, &block)
            end
          end
        end
        alias call request

        private

        def logged_request(method, url, client)
          label = method.to_s.upcase
          safe_url = sanitize_url(url)
          client.logger.debug { "BC API #{label} #{safe_url}" }
          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          result = yield

          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
          client.logger.debug { "BC API #{label} completed in #{elapsed.round(3)}s" }
          result
        rescue BusinessCentralError => e
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
          client.logger.warn do
            "BC API #{label} #{safe_url} failed: #{e.class} (#{elapsed.round(3)}s)"
          end
          raise
        end

        def sanitize_url(url)
          uri = URI(url)
          uri.query = '[filtered]' if uri.query
          uri.to_s
        rescue URI::InvalidURIError
          '[invalid-url]'
        end

        def request_with_retry(client)
          retries = 0
          begin
            yield
          rescue RateLimitException => e
            retries += 1
            raise if retries > client.max_retries

            sleep(e.retry_after || (client.retry_delay * (2**(retries - 1))))
            retry
          end
        end

        def perform(http_class, client, url, method, options, &block)
          handle_response do
            uri = URI(url)
            req = build_request(http_class, uri, method, options, &block)
            apply_auth(req, client)
            execute(uri, client, req)
          end
        end

        def build_request(http_class, uri, method, options)
          etag = options[:etag]
          params = options[:params]

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

          raise_status_error(status, raw, response)
        end

        def raise_status_error(status, raw, response)
          raise_rate_limit(raw) if Response.rate_limited?(status)
          raise_http_error(status, response)
          raise_bc_error(status, response)
        end

        def raise_http_error(status, response)
          raise UnauthorizedException if Response.unauthorized?(status)
          raise ForbiddenException if Response.forbidden?(status)
          raise NotFoundException if Response.not_found?(status)
          raise_detailed_http_error(status, response)
        end

        def raise_detailed_http_error(status, response)
          msg = error_message(status, response)
          raise ConflictException, msg if Response.conflict?(status)
          raise UnprocessableEntityException, msg if Response.unprocessable?(status)
          raise ApiException, "#{status} - Server error" if Response.server_error?(status)
        end

        def raise_rate_limit(raw)
          raise RateLimitException, raw['Retry-After']&.to_i
        end

        def raise_bc_error(status, response)
          error = response&.fetch(:error, nil)
          raise_bc_code_error(status, error) if error
          raise ApiException, "#{status} - API call failed"
        end

        def raise_bc_code_error(status, error)
          code = error[:code]
          raise CompanyNotFoundException if code == 'Internal_CompanyNotFound'
          raise ConflictException, error[:message] if code&.match?(/^EditConflict/)
          raise ForbiddenException if code&.match?(/^Permission/)
          raise ApiException, "#{status} - #{code} #{error[:message]}"
        end

        def error_message(status, response)
          error = response&.fetch(:error, nil)
          return "#{status} - #{error[:code]}: #{error[:message]}" if error

          "#{status} - API call failed"
        end
      end
    end
  end
end
