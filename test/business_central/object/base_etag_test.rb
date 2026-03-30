# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/base_etag_test.rb

class BusinessCentral::Object::BaseEtagTest < Minitest::Test
  def setup
    @company_id = '123456'
    @client = BusinessCentral::Client.new(default_company_id: @company_id)
    @vendor_url = "https://api.businesscentral.dynamics.com/v2.0/production/api/v1.0/companies(#{@company_id})/vendors"
  end

  def test_update_with_etag_skips_get
    vendor_id = '456'

    stub_request(:patch, "#{@vendor_url}(#{vendor_id})")
      .to_return(status: 200, body: '{"displayName": "Updated"}')

    @client.vendors.update(vendor_id, { display_name: 'Updated' }, etag: 'W/"known"')

    assert_requested(:patch, /vendors/, times: 1)
    assert_not_requested(:get, "#{@vendor_url}(#{vendor_id})")
  end

  def test_update_without_etag_fetches_first
    vendor_id = '456'

    stub_request(:get, "#{@vendor_url}(#{vendor_id})")
      .to_return(
        status: 200,
        body: { '@odata.etag': 'W/"fetched"', displayName: 'Old' }.to_json
      )

    stub_request(:patch, "#{@vendor_url}(#{vendor_id})")
      .to_return(status: 200, body: '{"displayName": "Updated"}')

    @client.vendors.update(vendor_id, { display_name: 'Updated' })

    assert_requested(:get, /vendors/, times: 1)
    assert_requested(:patch, /vendors/, times: 1)
  end

  def test_update_sends_provided_etag
    vendor_id = '456'
    etag = 'W/"my-etag"'

    stub_request(:patch, "#{@vendor_url}(#{vendor_id})")
      .to_return(status: 200, body: '{}')

    @client.vendors.update(vendor_id, { display_name: 'X' }, etag:)

    assert_requested(:patch, /vendors/) do |req|
      assert_equal etag, req.headers['If-Match']
    end
  end

  def test_destroy_with_etag_skips_get
    vendor_id = '456'

    stub_request(:delete, "#{@vendor_url}(#{vendor_id})")
      .to_return(status: 204)

    @client.vendors.destroy(vendor_id, etag: 'W/"known"')

    assert_requested(:delete, /vendors/, times: 1)
    assert_not_requested(:get, "#{@vendor_url}(#{vendor_id})")
  end

  def test_destroy_without_etag_fetches_first
    vendor_id = '456'

    stub_request(:get, "#{@vendor_url}(#{vendor_id})")
      .to_return(
        status: 200,
        body: { '@odata.etag': 'W/"fetched"' }.to_json
      )

    stub_request(:delete, "#{@vendor_url}(#{vendor_id})")
      .to_return(status: 204)

    @client.vendors.destroy(vendor_id)

    assert_requested(:get, /vendors/, times: 1)
    assert_requested(:delete, /vendors/, times: 1)
  end

  def test_destroy_sends_provided_etag
    vendor_id = '456'
    etag = 'W/"delete-etag"'

    stub_request(:delete, "#{@vendor_url}(#{vendor_id})")
      .to_return(status: 204)

    @client.vendors.destroy(vendor_id, etag:)

    assert_requested(:delete, /vendors/) do |req|
      assert_equal etag, req.headers['If-Match']
    end
  end

  def test_update_backward_compatible
    vendor_id = 1

    stub_request(:get, /vendors\(#{vendor_id}\)/)
      .to_return(
        status: 200,
        body: { '@odata.etag': '111', displayName: 'vendor1' }.to_json
      )

    stub_request(:patch, /vendors\(#{vendor_id}\)/)
      .to_return(
        status: 200,
        body: { displayName: 'vendor2' }.to_json
      )

    response = @client.vendors.update(vendor_id, { display_name: 'vendor2' })
    assert_equal 'vendor2', response[:display_name]
  end
end
