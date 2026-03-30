# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/web_service_etag_test.rb

class BusinessCentral::WebServiceEtagTest < Minitest::Test
  def setup
    @client = BusinessCentral::Client.new
    @web_service = BusinessCentral::WebService.new(client: @client)
  end

  def test_patch_with_etag_skips_get
    stub_request(:patch, /Company/).to_return(
      status: 200,
      body: { displayName: 'updated' }.to_json
    )

    response = @web_service.object('Company').patch(
      { display_name: 'updated' }, etag: 'W/"known"'
    )

    assert_equal 'updated', response[:display_name]
    assert_not_requested(:get, /Company/)
  end

  def test_patch_without_etag_fetches_first
    stub_request(:get, /Company/).to_return(
      status: 200,
      body: { '@odata.etag': 'W/"fetched"', displayName: 'old' }.to_json
    )

    stub_request(:patch, /Company/).to_return(
      status: 200,
      body: { displayName: 'updated' }.to_json
    )

    @web_service.object('Company').patch({ display_name: 'updated' })

    assert_requested(:get, /Company/, times: 1)
    assert_requested(:patch, /Company/, times: 1)
  end

  def test_delete_with_etag_skips_get
    stub_request(:delete, /Company/).to_return(status: 204)

    assert @web_service.object('Company').delete(etag: 'W/"known"')
    assert_not_requested(:get, /Company/)
  end

  def test_delete_without_etag_fetches_first
    stub_request(:get, /Company/).to_return(
      status: 200,
      body: { '@odata.etag': 'W/"fetched"', displayName: 'old' }.to_json
    )

    stub_request(:delete, /Company/).to_return(status: 204)

    @web_service.object('Company').delete

    assert_requested(:get, /Company/, times: 1)
    assert_requested(:delete, /Company/, times: 1)
  end
end
