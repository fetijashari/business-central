# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/client_security_test.rb

class BusinessCentral::ClientSecurityTest < Minitest::Test
  # -- Timeout configuration --

  def test_default_open_timeout
    client = BusinessCentral::Client.new
    assert_equal 30, client.open_timeout
  end

  def test_default_read_timeout
    client = BusinessCentral::Client.new
    assert_equal 60, client.read_timeout
  end

  def test_custom_open_timeout
    client = BusinessCentral::Client.new(open_timeout: 10)
    assert_equal 10, client.open_timeout
  end

  def test_custom_read_timeout
    client = BusinessCentral::Client.new(read_timeout: 120)
    assert_equal 120, client.read_timeout
  end

  # -- Debug output configuration --

  def test_default_debug_is_false
    client = BusinessCentral::Client.new
    assert_equal false, client.debug
  end

  def test_default_debug_output_is_stdout
    client = BusinessCentral::Client.new
    assert_equal $stdout, client.debug_output
  end

  def test_custom_debug_output
    output = StringIO.new
    client = BusinessCentral::Client.new(debug_output: output)
    assert_equal output, client.debug_output
  end

  # -- URL validation --

  def test_default_url_passes_validation
    client = BusinessCentral::Client.new
    assert_match(%r{^https://}, client.url)
  end

  def test_custom_https_url_accepted
    url = 'https://custom.businesscentral.dynamics.com/v2.0/api/v1.0'
    client = BusinessCentral::Client.new(url:)
    assert_equal url, client.url
  end

  def test_rejects_http_url
    error = assert_raises(ArgumentError) do
      BusinessCentral::Client.new(url: 'http://evil.com/api')
    end
    assert_includes error.message, 'HTTPS'
  end

  def test_rejects_ftp_url
    assert_raises(ArgumentError) do
      BusinessCentral::Client.new(url: 'ftp://evil.com/api')
    end
  end

  def test_rejects_http_web_service_url
    assert_raises(ArgumentError) do
      BusinessCentral::Client.new(web_service_url: 'http://evil.com/odata')
    end
  end

  def test_rejects_http_oauth2_login_url
    assert_raises(ArgumentError) do
      BusinessCentral::Client.new(oauth2_login_url: 'http://evil.com/oauth')
    end
  end

  def test_web_service_url_has_default
    client = BusinessCentral::Client.new
    assert_match(%r{^https://.*ODataV4$}, client.web_service_url)
  end

  def test_rejects_file_protocol_url
    assert_raises(ArgumentError) do
      BusinessCentral::Client.new(url: 'file:///etc/passwd')
    end
  end

  def test_rejects_javascript_protocol_url
    assert_raises(ArgumentError) do
      BusinessCentral::Client.new(url: 'javascript:alert(1)')
    end
  end

  def test_validation_error_includes_field_name
    error = assert_raises(ArgumentError) do
      BusinessCentral::Client.new(url: 'http://bad.com')
    end
    assert_includes error.message, 'url'
  end

  def test_validation_error_includes_scheme
    error = assert_raises(ArgumentError) do
      BusinessCentral::Client.new(url: 'http://bad.com')
    end
    assert_includes error.message, 'http'
  end

  # -- Frozen constants --

  def test_default_url_is_frozen
    assert BusinessCentral::Client::DEFAULT_URL.frozen?
  end

  def test_default_login_url_is_frozen
    assert BusinessCentral::Client::DEFAULT_LOGIN_URL.frozen?
  end

  def test_default_url_cannot_be_mutated
    assert_raises(FrozenError) do
      BusinessCentral::Client::DEFAULT_URL << '/hacked'
    end
  end

  def test_default_login_url_cannot_be_mutated
    assert_raises(FrozenError) do
      BusinessCentral::Client::DEFAULT_LOGIN_URL << '/hacked'
    end
  end

  def test_web_service_default_url_is_frozen
    assert BusinessCentral::WebService::DEFAULT_URL.frozen?
  end

  def test_attachments_object_constant_is_frozen
    assert BusinessCentral::Object::Attachments::OBJECT.frozen?
  end

  def test_rejects_malformed_url
    assert_raises(ArgumentError) do
      BusinessCentral::Client.new(url: 'ht tp://not valid')
    end
  end

  # -- OAuth2 client memoization --

  def test_oauth2_client_is_memoized
    client = BusinessCentral::Client.new
    first = client.send(:oauth2_client)
    second = client.send(:oauth2_client)
    assert_same first, second
  end

  def test_oauth2_client_uses_request_body_auth_scheme
    client = BusinessCentral::Client.new(
      application_id: 'test-id',
      secret_key: 'test-secret',
      oauth2_login_url: 'https://login.microsoftonline.com/tenant'
    )
    oauth_client = client.send(:oauth2_client)
    assert_equal :request_body, oauth_client.options[:auth_scheme]
  end
end
