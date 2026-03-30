# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/exceptions_extended_test.rb

class BusinessCentral::ExceptionsExtendedTest < Minitest::Test
  def test_api_exception_message_accessible_via_standard_error
    error = BusinessCentral::ApiException.new('Something went wrong')
    assert_equal 'Something went wrong', error.message
  end

  def test_api_exception_message_survives_rescue
    raise BusinessCentral::ApiException, 'API failed'
  rescue StandardError => e
    assert_equal 'API failed', e.message
  end

  def test_api_exception_inherits_from_business_central_error
    error = BusinessCentral::ApiException.new('test')
    assert_kind_of BusinessCentral::BusinessCentralError, error
    assert_kind_of StandardError, error
  end

  def test_api_exception_to_s_returns_message
    error = BusinessCentral::ApiException.new('detail here')
    assert_equal 'detail here', error.to_s
  end

  def test_all_exceptions_inherit_from_business_central_error
    exceptions = [
      BusinessCentral::ApiException.new('test'),
      BusinessCentral::CompanyNotFoundException.new,
      BusinessCentral::UnauthorizedException.new,
      BusinessCentral::NotFoundException.new,
      BusinessCentral::InvalidObjectURLException.new,
      BusinessCentral::InvalidClientException.new,
      BusinessCentral::InvalidGrantException.new('test')
    ]
    exceptions.each do |e|
      assert_kind_of BusinessCentral::BusinessCentralError, e,
                     "#{e.class} should inherit from BusinessCentralError"
    end
  end

  def test_all_exceptions_catchable_as_standard_error
    exceptions = [
      BusinessCentral::ApiException.new('test'),
      BusinessCentral::CompanyNotFoundException.new,
      BusinessCentral::UnauthorizedException.new,
      BusinessCentral::NotFoundException.new,
      BusinessCentral::InvalidObjectURLException.new,
      BusinessCentral::InvalidClientException.new,
      BusinessCentral::InvalidGrantException.new('test')
    ]
    exceptions.each do |e|
      assert_kind_of StandardError, e,
                     "#{e.class} should be catchable as StandardError"
    end
  end
end
