# frozen_string_literal: true

module BusinessCentral
  class Client
    using Refinements::Strings

    include BusinessCentral::Object::ObjectHelper

    DEFAULT_LOGIN_URL = 'https://login.microsoftonline.com/common'

    DEFAULT_URL = 'https://api.businesscentral.dynamics.com/v2.0/production/api/v1.0'

    DEFAULT_OPEN_TIMEOUT = 30
    DEFAULT_READ_TIMEOUT = 60

    attr_reader :username,
                :password,
                :application_id,
                :secret_key,
                :url,
                :web_service_url,
                :oauth2_login_url,
                :oauth2_access_token,
                :default_company_id,
                :debug,
                :debug_output,
                :open_timeout,
                :read_timeout

    alias access_token oauth2_access_token

    def initialize(options = {})
      opts = options.dup
      assign_credentials(opts)
      assign_urls(opts)
      assign_options(opts)
      validate_urls!
    end

    def authorize(params = {}, oauth_authorize_callback: '')
      params[:redirect_uri] = oauth_authorize_callback
      begin
        oauth2_client.auth_code.authorize_url(params)
      rescue OAuth2::Error => e
        handle_error(e)
      end
    end

    def request_token(code = '', oauth_token_callback: '')
      oauth2_client.auth_code.get_token(code, redirect_uri: oauth_token_callback)
    rescue OAuth2::Error => e
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
      @oauth2_access_token.refresh!
    rescue OAuth2::Error => e
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
    end

    def assign_urls(opts)
      @url = opts.delete(:url) || DEFAULT_URL
      @web_service_url = opts.delete(:web_service_url)
      @oauth2_login_url = opts.delete(:oauth2_login_url) || DEFAULT_LOGIN_URL
    end

    def assign_options(opts)
      @default_company_id = opts.delete(:default_company_id)
      @debug = opts.delete(:debug) || false
      @debug_output = opts.delete(:debug_output) || $stdout
      @open_timeout = opts.delete(:open_timeout) || DEFAULT_OPEN_TIMEOUT
      @read_timeout = opts.delete(:read_timeout) || DEFAULT_READ_TIMEOUT
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
      case error.code
      when 'invalid_client'
        raise InvalidClientException
      when 'invalid_grant'
        raise InvalidGrantException, error.message
      end
      raise ApiException, error.message
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
