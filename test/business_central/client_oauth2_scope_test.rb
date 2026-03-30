# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/client_oauth2_scope_test.rb

class BusinessCentral::ClientOAuth2ScopeTest < Minitest::Test
  def test_default_scope
    client = BusinessCentral::Client.new(
      application_id: 'app-id',
      secret_key: 'secret'
    )
    assert_equal 'https://api.businesscentral.dynamics.com/.default', client.oauth2_scope
  end

  def test_custom_scope
    scope = 'https://api.businesscentral.dynamics.com/Financials.ReadWrite.All'
    client = BusinessCentral::Client.new(
      application_id: 'app-id',
      secret_key: 'secret',
      oauth2_scope: scope
    )
    assert_equal scope, client.oauth2_scope
  end

  def test_authorize_includes_scope_in_url
    client = BusinessCentral::Client.new(
      application_id: 'app-id',
      secret_key: 'secret',
      oauth2_login_url: 'https://login.microsoftonline.com/tenant'
    )

    url = client.authorize(oauth_authorize_callback: 'https://cb.example.com')
    assert_includes url, 'scope='
  end

  def test_authorize_allows_scope_override
    client = BusinessCentral::Client.new(
      application_id: 'app-id',
      secret_key: 'secret',
      oauth2_login_url: 'https://login.microsoftonline.com/tenant'
    )

    url = client.authorize(
      { scope: 'custom_scope' },
      oauth_authorize_callback: 'https://cb.example.com'
    )
    assert_includes url, 'scope=custom_scope'
  end
end
