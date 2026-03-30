# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/request_security_test.rb

class BusinessCentral::Object::RequestSecurityTest < Minitest::Test
  def setup
    @url = BusinessCentral::Client::DEFAULT_URL
    @client = BusinessCentral::Client.new
  end

  # -- HTTP method whitelist --

  def test_http_methods_constant_is_frozen
    assert BusinessCentral::Object::Request::HTTP_METHODS.frozen?
  end

  def test_http_methods_maps_get
    assert_equal Net::HTTP::Get, BusinessCentral::Object::Request::HTTP_METHODS[:get]
  end

  def test_http_methods_maps_post
    assert_equal Net::HTTP::Post, BusinessCentral::Object::Request::HTTP_METHODS[:post]
  end

  def test_http_methods_maps_patch
    assert_equal Net::HTTP::Patch, BusinessCentral::Object::Request::HTTP_METHODS[:patch]
  end

  def test_http_methods_maps_delete
    assert_equal Net::HTTP::Delete, BusinessCentral::Object::Request::HTTP_METHODS[:delete]
  end

  def test_rejects_unsupported_http_method
    assert_raises(ArgumentError) do
      BusinessCentral::Object::Request.request(:put, @client, @url)
    end
  end

  def test_rejects_arbitrary_method_name
    assert_raises(ArgumentError) do
      BusinessCentral::Object::Request.request(:exec, @client, @url)
    end
  end

  def test_rejects_nil_method
    assert_raises(ArgumentError) do
      BusinessCentral::Object::Request.request(nil, @client, @url)
    end
  end

  def test_rejects_string_method
    assert_raises(ArgumentError) do
      BusinessCentral::Object::Request.request('get', @client, @url)
    end
  end

  def test_argument_error_includes_method_name
    error = assert_raises(ArgumentError) do
      BusinessCentral::Object::Request.request(:put, @client, @url)
    end
    assert_includes error.message, 'put'
  end

  # -- TLS and timeouts verified via successful requests --

  def test_get_request_works_with_new_http_start
    stub_request(:get, @url)
      .to_return(status: 200, body: { value: [{ displayName: 'V1' }] }.to_json)

    response = BusinessCentral::Object::Request.get(@client, @url)
    assert_equal 'V1', response.first[:display_name]
  end

  def test_post_request_works_with_new_http_start
    stub_request(:post, @url)
      .to_return(status: 201, body: { displayName: 'New' }.to_json)

    response = BusinessCentral::Object::Request.post(@client, @url, display_name: 'New')
    assert_equal 'New', response[:display_name]
  end

  def test_patch_request_works_with_new_http_start
    stub_request(:patch, @url)
      .to_return(status: 200, body: { displayName: 'Updated' }.to_json)

    response = BusinessCentral::Object::Request.patch(@client, @url, 'W/"etag"',
                                                      display_name: 'Updated')
    assert_equal 'Updated', response[:display_name]
  end

  def test_delete_request_works_with_new_http_start
    stub_request(:delete, @url).to_return(status: 204)
    assert BusinessCentral::Object::Request.delete(@client, @url, 'W/"etag"')
  end

  def test_call_is_alias_for_request
    assert_equal(
      BusinessCentral::Object::Request.method(:request),
      BusinessCentral::Object::Request.method(:call)
    )
  end
end
