# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/filtered_debug_output_test.rb

class BusinessCentral::Object::FilteredDebugOutputTest < Minitest::Test
  def setup
    @output = StringIO.new
    @filter = BusinessCentral::Object::FilteredDebugOutput.new(@output)
  end

  def test_redacts_bearer_authorization_header
    @filter << 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9'
    assert_includes @output.string, 'Authorization: [REDACTED]'
    refute_includes @output.string, 'eyJhbGciOiJSUzI1Ni'
  end

  def test_redacts_basic_authorization_header
    @filter << 'Authorization: Basic dXNlcjpwYXNzd29yZA=='
    assert_includes @output.string, 'Authorization: [REDACTED]'
    refute_includes @output.string, 'dXNlcjpwYXNzd29yZA=='
  end

  def test_redacts_cookie_header
    @filter << 'Cookie: session=abc123secret'
    assert_includes @output.string, 'Cookie: [REDACTED]'
    refute_includes @output.string, 'abc123secret'
  end

  def test_redacts_set_cookie_header
    @filter << 'Set-Cookie: session=abc123; Path=/'
    assert_includes @output.string, 'Set-Cookie: [REDACTED]'
    refute_includes @output.string, 'abc123'
  end

  def test_redacts_x_api_key_header
    @filter << 'X-Api-Key: sk-live-12345secret'
    assert_includes @output.string, 'X-Api-Key: [REDACTED]'
    refute_includes @output.string, 'sk-live-12345secret'
  end

  def test_preserves_non_sensitive_headers
    @filter << 'Content-Type: application/json'
    assert_includes @output.string, 'Content-Type: application/json'
  end

  def test_preserves_accept_header
    @filter << 'Accept: application/json'
    assert_includes @output.string, 'Accept: application/json'
  end

  def test_preserves_if_match_header
    @filter << 'If-Match: W/"etag-value"'
    assert_includes @output.string, 'If-Match: W/"etag-value"'
  end

  def test_preserves_request_body
    @filter << '{"displayName": "Test Vendor"}'
    assert_includes @output.string, '{"displayName": "Test Vendor"}'
  end

  def test_handles_case_insensitive_authorization
    @filter << 'authorization: Bearer secret_token'
    assert_includes @output.string, '[REDACTED]'
    refute_includes @output.string, 'secret_token'
  end

  def test_handles_nil_message
    @filter << nil
    assert_equal '', @output.string
  end

  def test_handles_multiline_output_with_mixed_headers
    message = "GET /api/v1.0/companies HTTP/1.1\r\n" \
              "Authorization: Bearer secret\r\n" \
              "Content-Type: application/json\r\n" \
              "Accept: application/json\r\n"
    @filter << message
    refute_includes @output.string, 'Bearer secret'
    assert_includes @output.string, 'Content-Type: application/json'
    assert_includes @output.string, 'Accept: application/json'
  end

  def test_print_method_delegates_to_append
    @filter.print('Authorization: Bearer secret')
    assert_includes @output.string, '[REDACTED]'
    refute_includes @output.string, 'secret'
  end

  def test_sensitive_pattern_constant_is_frozen
    assert BusinessCentral::Object::FilteredDebugOutput::SENSITIVE_PATTERN.frozen?
  end

  def test_defaults_to_stdout
    filter = BusinessCentral::Object::FilteredDebugOutput.new
    assert_instance_of BusinessCentral::Object::FilteredDebugOutput, filter
  end
end
