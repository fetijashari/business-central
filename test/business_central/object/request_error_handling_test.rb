# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/request_error_handling_test.rb

class BusinessCentral::Object::RequestErrorHandlingTest < Minitest::Test
  def setup
    @url = BusinessCentral::Client::DEFAULT_URL
    @client = BusinessCentral::Client.new
  end

  def test_403_raises_forbidden
    stub_request(:get, @url).to_return(status: 403, body: '{}')

    assert_raises(BusinessCentral::ForbiddenException) do
      BusinessCentral::Object::Request.get(@client, @url)
    end
  end

  def test_409_raises_conflict
    stub_request(:patch, @url).to_return(
      status: 409,
      body: '{"error": {"code": "EditConflict", "message": "Modified"}}'
    )

    assert_raises(BusinessCentral::ConflictException) do
      BusinessCentral::Object::Request.patch(@client, @url, 'etag', {})
    end
  end

  def test_422_raises_unprocessable_entity
    stub_request(:post, @url).to_return(
      status: 422,
      body: '{"error": {"code": "ValidationFailed", "message": "Required"}}'
    )

    assert_raises(BusinessCentral::UnprocessableEntityException) do
      BusinessCentral::Object::Request.post(@client, @url, {})
    end
  end

  def test_500_raises_api_exception
    stub_request(:get, @url).to_return(
      status: 500,
      body: '{"error": {"code": "InternalError", "message": "Fail"}}'
    )

    error = assert_raises(BusinessCentral::ApiException) do
      BusinessCentral::Object::Request.get(@client, @url)
    end
    assert_match(/Server error/, error.message)
  end

  def test_503_raises_api_exception
    stub_request(:get, @url).to_return(status: 503, body: '{}')

    error = assert_raises(BusinessCentral::ApiException) do
      BusinessCentral::Object::Request.get(@client, @url)
    end
    assert_match(/Server error/, error.message)
  end

  def test_edit_conflict_bc_code_raises_conflict
    stub_request(:patch, @url).to_return(
      status: 400,
      body: '{"error": {"code": "EditConflict_Resolve", "message": "Mismatch"}}'
    )

    assert_raises(BusinessCentral::ConflictException) do
      BusinessCentral::Object::Request.patch(@client, @url, 'etag', {})
    end
  end

  def test_permission_bc_code_raises_forbidden
    stub_request(:delete, @url).to_return(
      status: 400,
      body: '{"error": {"code": "Permission_Required", "message": "No access"}}'
    )

    assert_raises(BusinessCentral::ForbiddenException) do
      BusinessCentral::Object::Request.delete(@client, @url, 'etag')
    end
  end

  def test_401_still_raises_unauthorized
    stub_request(:get, @url).to_return(status: 401, body: '{}')

    assert_raises(BusinessCentral::UnauthorizedException) do
      BusinessCentral::Object::Request.get(@client, @url)
    end
  end

  def test_404_still_raises_not_found
    stub_request(:get, @url).to_return(status: 404, body: '{}')

    assert_raises(BusinessCentral::NotFoundException) do
      BusinessCentral::Object::Request.get(@client, @url)
    end
  end

  def test_new_exceptions_inherit_from_business_central_error
    [
      BusinessCentral::ForbiddenException.new,
      BusinessCentral::ConflictException.new('msg'),
      BusinessCentral::BadRequestException.new('msg'),
      BusinessCentral::UnprocessableEntityException.new('msg'),
      BusinessCentral::RateLimitException.new
    ].each do |e|
      assert_kind_of BusinessCentral::BusinessCentralError, e,
                     "#{e.class} should inherit from BusinessCentralError"
    end
  end

  # Response status helper tests

  def test_response_bad_request
    assert BusinessCentral::Object::Response.bad_request?(400)
    refute BusinessCentral::Object::Response.bad_request?(401)
  end

  def test_response_forbidden
    assert BusinessCentral::Object::Response.forbidden?(403)
  end

  def test_response_conflict
    assert BusinessCentral::Object::Response.conflict?(409)
  end

  def test_response_unprocessable
    assert BusinessCentral::Object::Response.unprocessable?(422)
  end

  def test_response_rate_limited
    assert BusinessCentral::Object::Response.rate_limited?(429)
  end

  def test_response_server_error
    assert BusinessCentral::Object::Response.server_error?(500)
    assert BusinessCentral::Object::Response.server_error?(503)
    refute BusinessCentral::Object::Response.server_error?(499)
  end

  def test_malformed_json_raises_api_exception
    stub_request(:get, @url).to_return(status: 200, body: 'not valid json')

    assert_raises(BusinessCentral::ApiException) do
      BusinessCentral::Object::Request.get(@client, @url)
    end
  end
end
