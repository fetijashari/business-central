# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/request_rate_limit_test.rb

class BusinessCentral::Object::RequestRateLimitTest < Minitest::Test
  def setup
    @url = BusinessCentral::Client::DEFAULT_URL
    @client = BusinessCentral::Client.new(
      max_retries: 2,
      retry_delay: 0.01
    )
  end

  def test_retries_on_429_then_succeeds
    stub_request(:get, @url)
      .to_return(
        { status: 429, headers: { 'Retry-After' => '0' }, body: '{}' },
        { status: 200, body: '{"value": []}' }
      )

    result = BusinessCentral::Object::Request.get(@client, @url)
    assert_equal [], result
    assert_requested(:get, @url, times: 2)
  end

  def test_raises_after_max_retries_exceeded
    stub_request(:get, @url)
      .to_return(status: 429, headers: { 'Retry-After' => '0' }, body: '{}')

    assert_raises(BusinessCentral::RateLimitException) do
      BusinessCentral::Object::Request.get(@client, @url)
    end

    assert_requested(:get, @url, times: 3)
  end

  def test_rate_limit_exception_has_retry_after
    error = BusinessCentral::RateLimitException.new(30)
    assert_equal 30, error.retry_after
    assert_match(/30/, error.message)
  end

  def test_rate_limit_exception_without_retry_after
    error = BusinessCentral::RateLimitException.new
    assert_nil error.retry_after
    assert_match(/unknown/, error.message)
  end

  def test_default_max_retries
    client = BusinessCentral::Client.new
    assert_equal 3, client.max_retries
  end

  def test_default_retry_delay
    client = BusinessCentral::Client.new
    assert_equal 1, client.retry_delay
  end

  def test_custom_max_retries
    client = BusinessCentral::Client.new(max_retries: 5)
    assert_equal 5, client.max_retries
  end

  def test_non_429_errors_are_not_retried
    stub_request(:get, @url)
      .to_return(status: 500, body: '{"error": {"code": "ServerError", "message": "fail"}}')

    assert_raises(BusinessCentral::ApiException) do
      BusinessCentral::Object::Request.get(@client, @url)
    end

    assert_requested(:get, @url, times: 1)
  end

  def test_rate_limit_inherits_from_business_central_error
    error = BusinessCentral::RateLimitException.new
    assert_kind_of BusinessCentral::BusinessCentralError, error
  end
end
