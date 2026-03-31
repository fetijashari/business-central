# frozen_string_literal: true

module BusinessCentral
  class Client
    using Refinements::Strings

    include BusinessCentral::Object::ObjectHelper

    DEFAULT_LOGIN_URL = 'https://login.microsoftonline.com/common'
    DEFAULT_BC_HOST = 'https://api.businesscentral.dynamics.com'
    DEFAULT_ENVIRONMENT = 'production'
    DEFAULT_API_VERSION = 'v1.0'
    DEFAULT_SCOPE = 'https://api.businesscentral.dynamics.com/.default'
    DEFAULT_OPEN_TIMEOUT = 30
    DEFAULT_READ_TIMEOUT = 60
    DEFAULT_MAX_RETRIES = 3
    DEFAULT_RETRY_DELAY = 1

    DEFAULT_URL = "#{DEFAULT_BC_HOST}/v2.0/#{DEFAULT_ENVIRONMENT}/api/#{DEFAULT_API_VERSION}".freeze

    attr_reader :username,
                :password,
                :application_id,
                :secret_key,
                :url,
                :web_service_url,
                :oauth2_login_url,
                :oauth2_access_token,
                :oauth2_scope,
                :default_company_id,
                :environment,
                :tenant_id,
                :api_version,
                :debug,
                :debug_output,
                :open_timeout,
                :read_timeout,
                :max_retries,
                :retry_delay,
                :logger

    alias access_token oauth2_access_token

    def initialize(options = {})
      opts = options.dup
      assign_credentials(opts)
      assign_environment(opts)
      assign_urls(opts)
      assign_options(opts)
      validate_urls!
    end

    def authorize(params = {}, oauth_authorize_callback: '')
      params[:redirect_uri] = oauth_authorize_callback
      params[:scope] ||= @oauth2_scope
      @logger.info { 'BC OAuth2: Starting authorization flow' }
      oauth2_client.auth_code.authorize_url(params)
    rescue OAuth2::Error => e
      @logger.warn { "BC OAuth2: Authorization failed - #{e.code}" }
      handle_error(e)
    end

    def request_token(code = '', oauth_token_callback: '')
      @logger.info { 'BC OAuth2: Requesting token' }
      token = oauth2_client.auth_code.get_token(
        code,
        redirect_uri: oauth_token_callback,
        scope: @oauth2_scope
      )
      @logger.info { 'BC OAuth2: Token acquired' }
      token
    rescue OAuth2::Error => e
      @logger.warn { "BC OAuth2: Token request failed - #{e.code}" }
      handle_error(e)
    end

    def authorize_from_token(token: '', refresh_token: '', expires_at: nil, expires_in: nil)
      @oauth2_access_token = OAuth2::AccessToken.new(
        oauth2_client,
        token,
        refresh_token:,
        expires_at:,
        expires_in:
      )
    end

    def refresh_token
      @logger.info { 'BC OAuth2: Refreshing token' }
      result = @oauth2_access_token.refresh!
      @logger.info { 'BC OAuth2: Token refreshed' }
      result
    rescue OAuth2::Error => e
      @logger.warn { "BC OAuth2: Token refresh failed - #{e.code}" }
      handle_error(e)
    end

    def web_service
      @web_service ||= BusinessCentral::WebService.new(client: self, url: web_service_url)
    end

    private

    def assign_credentials(opts)
      @username = opts.delete(:username)
      @password = opts.delete(:password)
      @application_id = opts.delete(:application_id)
      @secret_key = opts.delete(:secret_key)
      @oauth2_scope = opts.delete(:oauth2_scope) || DEFAULT_SCOPE
    end

    def assign_environment(opts)
      @environment = opts.delete(:environment) || DEFAULT_ENVIRONMENT
      @tenant_id = opts.delete(:tenant_id)
      @api_version = opts.delete(:api_version) || DEFAULT_API_VERSION
    end

    def assign_urls(opts)
      @oauth2_login_url = opts.delete(:oauth2_login_url) || DEFAULT_LOGIN_URL
      @url = opts.delete(:url) || build_api_url
      @web_service_url = opts.delete(:web_service_url) || build_odata_url
    end

    def assign_options(opts)
      @default_company_id = opts.delete(:default_company_id)
      @logger = opts.delete(:logger) || default_logger
      assign_http_options(opts)
    end

    def assign_http_options(opts)
      @debug = opts.delete(:debug) || false
      @debug_output = opts.delete(:debug_output) || $stdout
      @open_timeout = opts.delete(:open_timeout) || DEFAULT_OPEN_TIMEOUT
      @read_timeout = opts.delete(:read_timeout) || DEFAULT_READ_TIMEOUT
      @max_retries = opts.delete(:max_retries) || DEFAULT_MAX_RETRIES
      @retry_delay = opts.delete(:retry_delay) || DEFAULT_RETRY_DELAY
    end

    def default_logger
      Logger.new(File::NULL)
    end

    def build_api_url
      base = "#{DEFAULT_BC_HOST}/v2.0"
      base += "/#{@tenant_id}" if @tenant_id
      "#{base}/#{@environment}/api/#{@api_version}"
    end

    def build_odata_url
      base = "#{DEFAULT_BC_HOST}/v2.0"
      base += "/#{@tenant_id}" if @tenant_id
      "#{base}/#{@environment}/ODataV4"
    end

    def oauth2_client
      @oauth2_client ||= OAuth2::Client.new(
        @application_id,
        @secret_key,
        site: @oauth2_login_url,
        authorize_url: 'oauth2/authorize?resource=https://api.businesscentral.dynamics.com',
        token_url: 'oauth2/token?resource=https://api.businesscentral.dynamics.com'
      )
    end

    def handle_error(error)
      error_code = resolve_error_code(error)
      case error_code
      when 'invalid_client'
        raise InvalidClientException
      when 'invalid_grant'
        raise InvalidGrantException, error.message
      end
      raise ApiException, error.message
    end

    def resolve_error_code(error)
      code = error.code
      return code if %w[invalid_client invalid_grant].include?(code)

      extract_error_code(error) || code
    end

    def extract_error_code(error)
      resp = error.response
      if resp.is_a?(Hash)
        desc = resp[:error_description].to_s
        return 'invalid_grant' if desc.include?('invalid_grant')
        return 'invalid_client' if desc.include?('invalid_client')
        return resp[:error] || resp['error']
      end
      resp.parsed['error'] if resp.respond_to?(:parsed)
    rescue StandardError
      nil
    end

    def validate_urls!
      validate_url!(@url, 'url')
      validate_url!(@web_service_url, 'web_service_url')
      validate_url!(@oauth2_login_url, 'oauth2_login_url')
    end

    def validate_url!(url, name)
      return if url.nil?

      uri = URI.parse(url)
      return if uri.is_a?(URI::HTTPS)

      raise ArgumentError,
            "#{name} must use HTTPS scheme, got: #{uri.scheme || 'none'}"
    rescue URI::InvalidURIError => e
      raise ArgumentError, "#{name} is not a valid URL: #{e.message}"
    end
  end
end
