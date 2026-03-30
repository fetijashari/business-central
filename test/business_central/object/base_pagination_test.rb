# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/base_pagination_test.rb

class BusinessCentral::Object::BasePaginationTest < Minitest::Test
  def setup
    @company_id = '123456'
    @client = BusinessCentral::Client.new(default_company_id: @company_id)
  end

  def test_find_all_with_top
    stub_request(:get, /vendors.*\$top=5/)
      .to_return(status: 200, body: '{"value": []}')

    @client.vendors.find_all(top: 5)
    assert_requested(:get, /\$top=5/)
  end

  def test_find_all_with_skip
    stub_request(:get, /vendors.*\$skip=10/)
      .to_return(status: 200, body: '{"value": []}')

    @client.vendors.find_all(skip: 10)
    assert_requested(:get, /\$skip=10/)
  end

  def test_find_all_with_order_by
    stub_request(:get, /vendors.*\$orderby/)
      .to_return(status: 200, body: '{"value": []}')

    @client.vendors.find_all(order_by: 'displayName asc')
    assert_requested(:get, /\$orderby=displayName/)
  end

  def test_find_all_with_select
    stub_request(:get, /vendors.*\$select/)
      .to_return(status: 200, body: '{"value": []}')

    @client.vendors.find_all(select: 'id,displayName')
    assert_requested(:get, /\$select=id,displayName/)
  end

  def test_find_all_with_expand
    stub_request(:get, /vendors.*\$expand/)
      .to_return(status: 200, body: '{"value": []}')

    @client.vendors.find_all(expand: 'defaultDimensions')
    assert_requested(:get, /\$expand=defaultDimensions/)
  end

  def test_where_with_pagination
    stub_request(:get, /vendors.*\$filter.*\$top/)
      .to_return(status: 200, body: '{"value": []}')

    @client.vendors.where("displayName eq '?'", 'Test', top: 10)
    assert_requested(:get, /\$filter=.*\$top=10/)
  end

  def test_find_all_without_params_backward_compatible
    stub_request(:get, /companies.*vendors$/)
      .to_return(status: 200, body: '{"value": []}')

    @client.vendors.find_all
    assert_requested(:get, /vendors$/)
  end

  def test_response_extracts_next_link
    body = {
      '@odata.nextLink' => 'https://api.example.com/next',
      'displayName' => 'V1'
    }.to_json

    response = BusinessCentral::Object::Response.new(body)
    assert_equal 'https://api.example.com/next', response.results[:next_link]
  end
end
