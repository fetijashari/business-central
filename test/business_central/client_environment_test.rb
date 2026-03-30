# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/client_environment_test.rb

class BusinessCentral::ClientEnvironmentTest < Minitest::Test
  # -- Environment --

  def test_default_environment_is_production
    client = BusinessCentral::Client.new
    assert_equal 'production', client.environment
    assert_includes client.url, '/production/'
  end

  def test_sandbox_environment
    client = BusinessCentral::Client.new(environment: 'sandbox')
    assert_equal 'sandbox', client.environment
    assert_includes client.url, '/sandbox/'
    refute_includes client.url, '/production/'
  end

  def test_custom_environment
    client = BusinessCentral::Client.new(environment: 'staging')
    assert_includes client.url, '/staging/'
  end

  # -- Tenant --

  def test_tenant_id_in_url
    client = BusinessCentral::Client.new(tenant_id: 'my-tenant-guid')
    assert_includes client.url, '/my-tenant-guid/'
  end

  def test_tenant_id_absent_when_not_set
    client = BusinessCentral::Client.new
    refute_includes client.url, '/v2.0//'
  end

  # -- API version --

  def test_default_api_version
    client = BusinessCentral::Client.new
    assert_equal 'v1.0', client.api_version
    assert_includes client.url, '/api/v1.0'
  end

  def test_custom_api_version
    client = BusinessCentral::Client.new(api_version: 'v2.0')
    assert_includes client.url, '/api/v2.0'
  end

  # -- Explicit URL override --

  def test_explicit_url_overrides_built_url
    explicit = 'https://custom.example.com/api/v1.0'
    client = BusinessCentral::Client.new(url: explicit, environment: 'sandbox')
    assert_equal explicit, client.url
  end

  # -- WebService URL --

  def test_web_service_url_includes_environment
    client = BusinessCentral::Client.new(environment: 'sandbox')
    assert_includes client.web_service_url, '/sandbox/ODataV4'
  end

  def test_web_service_url_includes_tenant
    client = BusinessCentral::Client.new(tenant_id: 'tid')
    assert_includes client.web_service_url, '/tid/'
  end

  def test_explicit_web_service_url_overrides
    explicit = 'https://custom.example.com/ODataV4'
    client = BusinessCentral::Client.new(web_service_url: explicit)
    assert_equal explicit, client.web_service_url
  end

  # -- Full URL structure --

  def test_full_url_with_all_params
    client = BusinessCentral::Client.new(
      tenant_id: 'tenant-123',
      environment: 'sandbox',
      api_version: 'v2.0'
    )
    expected = 'https://api.businesscentral.dynamics.com/v2.0/tenant-123/sandbox/api/v2.0'
    assert_equal expected, client.url
  end

  def test_full_odata_url_with_all_params
    client = BusinessCentral::Client.new(
      tenant_id: 'tenant-123',
      environment: 'sandbox'
    )
    expected = 'https://api.businesscentral.dynamics.com/v2.0/tenant-123/sandbox/ODataV4'
    assert_equal expected, client.web_service_url
  end
end
