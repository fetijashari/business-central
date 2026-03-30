# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/response_robustness_test.rb

class BusinessCentral::Object::ResponseRobustnessTest < Minitest::Test
  def test_valid_json_object
    response = BusinessCentral::Object::Response.new('{"displayName": "Test"}')
    assert_equal 'Test', response.results[:display_name]
  end

  def test_valid_json_array_with_value_key
    response = BusinessCentral::Object::Response.new('{"value": [{"displayName": "Test"}]}')
    assert_equal 1, response.results.length
    assert_equal 'Test', response.results.first[:display_name]
  end

  def test_empty_string_returns_nil
    response = BusinessCentral::Object::Response.new('')
    assert_nil response.results
  end

  def test_whitespace_string_returns_nil
    response = BusinessCentral::Object::Response.new('   ')
    assert_nil response.results
  end

  def test_malformed_json_raises_api_exception
    assert_raises(BusinessCentral::ApiException) do
      BusinessCentral::Object::Response.new('not valid json {{{')
    end
  end

  def test_truncated_json_raises_api_exception
    assert_raises(BusinessCentral::ApiException) do
      BusinessCentral::Object::Response.new('{"displayName": "Test')
    end
  end

  def test_malformed_json_error_includes_details
    error = assert_raises(BusinessCentral::ApiException) do
      BusinessCentral::Object::Response.new('invalid')
    end
    assert_match(/parse/i, error.message)
  end

  def test_empty_json_object
    response = BusinessCentral::Object::Response.new('{}')
    assert_equal({}, response.results)
  end

  def test_empty_value_array
    response = BusinessCentral::Object::Response.new('{"value": []}')
    assert_equal [], response.results
  end

  def test_converts_odata_etag
    body = '{"@odata.etag": "W/\\"123\\"", "displayName": "Test"}'
    response = BusinessCentral::Object::Response.new(body)
    assert_equal 'W/"123"', response.results[:etag]
  end

  def test_converts_odata_context
    body = '{"@odata.context": "https://example.com", "displayName": "Test"}'
    response = BusinessCentral::Object::Response.new(body)
    assert_equal 'https://example.com', response.results[:context]
  end

  def test_converts_odata_next_link
    body = '{"@odata.nextLink": "https://example.com/next", "displayName": "Test"}'
    response = BusinessCentral::Object::Response.new(body)
    assert_equal 'https://example.com/next', response.results[:next_link]
  end

  def test_converts_nested_hash
    json = '{"address": {"street": "123 Main", "city": "Seattle"}}'
    response = BusinessCentral::Object::Response.new(json)
    assert_equal '123 Main', response.results[:address][:street]
    assert_equal 'Seattle', response.results[:address][:city]
  end

  def test_converts_camel_case_to_snake_case
    json = '{"displayName": "Test", "phoneNumber": "555", "balanceDue": 100.5}'
    response = BusinessCentral::Object::Response.new(json)
    assert_equal 'Test', response.results[:display_name]
    assert_equal '555', response.results[:phone_number]
    assert_equal 100.5, response.results[:balance_due]
  end

  def test_handles_json_array_without_value_key
    response = BusinessCentral::Object::Response.new('[{"name": "Test"}]')
    assert_equal 1, response.results.length
  end
end
