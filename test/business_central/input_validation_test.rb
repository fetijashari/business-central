# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/input_validation_test.rb

class BusinessCentral::InputValidationTest < Minitest::Test
  def setup
    @client = BusinessCentral::Client.new(default_company_id: '123')
  end

  # -- ID validation --

  def test_find_by_id_rejects_nil
    assert_raises(ArgumentError) { @client.vendors.find_by_id(nil) }
  end

  def test_find_by_id_rejects_empty_string
    assert_raises(ArgumentError) { @client.vendors.find_by_id('') }
  end

  def test_find_by_id_rejects_blank_string
    assert_raises(ArgumentError) { @client.vendors.find_by_id('   ') }
  end

  def test_update_rejects_nil_id
    assert_raises(ArgumentError) { @client.vendors.update(nil, { display_name: 'X' }) }
  end

  def test_update_rejects_non_hash_params
    assert_raises(ArgumentError) { @client.vendors.update('123', 'not a hash') }
  end

  def test_destroy_rejects_nil_id
    assert_raises(ArgumentError) { @client.vendors.destroy(nil) }
  end

  def test_destroy_rejects_empty_id
    assert_raises(ArgumentError) { @client.vendors.destroy('') }
  end

  def test_find_by_id_accepts_guid
    stub_request(:get, /vendors/).to_return(
      status: 200, body: '{"displayName": "V"}'
    )
    result = @client.vendors.find_by_id('550e8400-e29b-41d4-a716-446655440000')
    assert_equal 'V', result[:display_name]
  end

  def test_find_by_id_accepts_numeric
    stub_request(:get, /vendors/).to_return(
      status: 200, body: '{"displayName": "V"}'
    )
    result = @client.vendors.find_by_id(12_345)
    assert_equal 'V', result[:display_name]
  end
end
