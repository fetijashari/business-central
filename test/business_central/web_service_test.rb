# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/web_service_test.rb

class BusinessCentral::WebServiceTest < Minitest::Test
  def setup
    @client = BusinessCentral::Client.new
    @web_service = BusinessCentral::WebService.new(client: @client)
  end

  def test_build_object_url
    ws = @web_service.object('Company/Vendors')
    assert_equal 'Company/Vendors', ws.object_url
  end

  def test_build_object_url_with_array_template_values
    ws = @web_service.object("Company('?')", 'business1')
    assert_equal "Company('business1')", ws.object_url
  end

  def test_build_object_url_with_hash_template_values
    ws = @web_service.object("Company(':business_name')", business_name: 'business1')
    assert_equal "Company('business1')", ws.object_url
  end

  def test_object_returns_new_instance
    ws = @web_service.object('Company')
    refute_same @web_service, ws
  end

  def test_original_not_mutated_by_object
    @web_service.object('Company')
    assert_nil @web_service.object_url
  end

  def test_object_get_request
    stub_request(:get, /Company/)
      .to_return(
        status: 200,
        body: {
          value: [
            {
              displayName: 'business1'
            }
          ]
        }.to_json
      )

    response = @web_service.object('Company').get
    assert_equal 'business1', response.first[:display_name]
  end

  def test_object_post_request
    stub_request(:post, /Company/)
      .to_return(
        status: 200,
        body: {
          displayName: 'business2'
        }.to_json
      )

    response = @web_service.object('Company').post(
      display_name: 'business2'
    )
    assert_equal 'business2', response[:display_name]
  end

  def test_object_patch_request
    test_company_name = 'business3'
    stub_request(:get, /Company\('#{test_company_name}'\)/)
      .to_return(
        status: 200,
        body: {
          etag: '112',
          displayName: 'business3'
        }.to_json
      )

    stub_request(:patch, /Company\('#{test_company_name}'\)/)
      .to_return(
        status: 200,
        body: {
          displayName: 'business4'
        }.to_json
      )

    response = @web_service.object("Company('?')", test_company_name).patch(
      { display_name: 'business4' }
    )
    assert_equal 'business4', response[:display_name]
  end

  def test_object_delete_request
    test_company_name = 'business5'
    stub_request(:get, /Company\('#{test_company_name}'\)/)
      .to_return(
        status: 200,
        body: {
          etag: '113',
          displayName: 'business5'
        }.to_json
      )

    stub_request(:delete, /Company\('#{test_company_name}'\)/)
      .to_return(status: 204)

    assert @web_service.object("Company('?')", test_company_name).delete
  end

  def test_raises_without_object_url
    assert_raises(BusinessCentral::InvalidObjectURLException) do
      @web_service.get
    end
  end
end
