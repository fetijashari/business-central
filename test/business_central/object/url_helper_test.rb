# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/url_helper_test.rb

class BusinessCentral::Object::URLHelperTest < Minitest::Test
  # Create a test class that includes the module
  class Helper
    extend BusinessCentral::Object::URLHelper

    using Refinements::Strings
  end

  # -- encode_url_object --

  def test_encode_url_object_preserves_slashes
    result = Helper.encode_url_object('Company/Vendors')
    assert_includes result, '/'
  end

  def test_encode_url_object_encodes_spaces
    result = Helper.encode_url_object("Company('My Company')")
    refute_includes result, ' '
  end

  def test_encode_url_object_simple_path
    result = Helper.encode_url_object('Company')
    assert_equal 'Company', result
  end

  # -- encode_url_params --

  def test_encode_url_params_spaces
    result = Helper.encode_url_params("name eq 'test'")
    refute_includes result, ' '
  end

  def test_encode_url_params_quotes
    result = Helper.encode_url_params("displayName eq 'Test'")
    assert_includes result, '%27'
  end

  # -- odata_encode --

  def test_odata_encode_escapes_single_quotes
    result = Helper.odata_encode("O'Brien")
    assert_equal "O''Brien", result
  end

  def test_odata_encode_no_quotes_unchanged
    result = Helper.odata_encode('Test')
    assert_equal 'Test', result
  end

  def test_odata_encode_multiple_quotes
    result = Helper.odata_encode("It's Tom's")
    assert_equal "It''s Tom''s", result
  end

  def test_odata_encode_does_not_mutate_original
    original = "O'Brien"
    Helper.odata_encode(original)
    assert_equal "O'Brien", original
  end
end
