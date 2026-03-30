# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/refinements/strings_test.rb

class Refinements::StringsTest < Minitest::Test
  using Refinements::Strings

  # -- blank? --

  def test_blank_empty_string
    assert ''.blank?
  end

  def test_blank_whitespace_only
    assert '   '.blank?
  end

  def test_blank_tab
    assert "\t".blank?
  end

  def test_blank_newline
    assert "\n".blank?
  end

  def test_blank_mixed_whitespace
    assert " \t\n\r ".blank?
  end

  def test_not_blank_with_content
    refute 'hello'.blank?
  end

  def test_not_blank_with_surrounding_whitespace
    refute ' hello '.blank?
  end

  def test_not_blank_with_zero
    refute '0'.blank?
  end

  # -- present? --

  def test_present_with_content
    assert 'hello'.present?
  end

  def test_not_present_when_empty
    refute ''.present?
  end

  def test_not_present_when_whitespace
    refute '   '.present?
  end

  # -- to_camel_case (lowercase first) --

  def test_camel_case_simple
    assert_equal 'displayName', 'display_name'.to_camel_case
  end

  def test_camel_case_multiple_underscores
    assert_equal 'thisIsALongName', 'this_is_a_long_name'.to_camel_case
  end

  def test_camel_case_single_word
    assert_equal 'name', 'name'.to_camel_case
  end

  def test_camel_case_already_camel
    assert_equal 'displayName', 'displayName'.to_camel_case
  end

  def test_camel_case_empty_string
    assert_equal '', ''.to_camel_case
  end

  def test_camel_case_single_char
    assert_equal 'a', 'a'.to_camel_case
  end

  # -- to_camel_case (uppercase first) --

  def test_camel_case_uppercase_first
    assert_equal 'DisplayName', 'display_name'.to_camel_case(uppercase_first_letter: true)
  end

  def test_camel_case_uppercase_single_word
    assert_equal 'Name', 'name'.to_camel_case(uppercase_first_letter: true)
  end

  def test_camel_case_uppercase_already_capitalized
    assert_equal 'DisplayName', 'DisplayName'.to_camel_case(uppercase_first_letter: true)
  end

  # -- to_snake_case --

  def test_snake_case_simple
    assert_equal 'display_name', 'displayName'.to_snake_case
  end

  def test_snake_case_uppercase_first
    assert_equal 'display_name', 'DisplayName'.to_snake_case
  end

  def test_snake_case_consecutive_caps
    assert_equal 'html_parser', 'HTMLParser'.to_snake_case
  end

  def test_snake_case_already_snake
    assert_equal 'display_name', 'display_name'.to_snake_case
  end

  def test_snake_case_with_dashes
    assert_equal 'display_name', 'display-name'.to_snake_case
  end

  def test_snake_case_single_word
    assert_equal 'name', 'name'.to_snake_case
  end

  def test_snake_case_empty_string
    assert_equal '', ''.to_snake_case
  end

  def test_snake_case_namespace
    assert_equal 'business_central/client', 'BusinessCentral::Client'.to_snake_case
  end

  # -- to_class_sym --

  def test_class_sym_simple
    assert_equal :DisplayName, 'display_name'.to_class_sym
  end

  def test_class_sym_single_word
    assert_equal :Name, 'name'.to_class_sym
  end

  def test_class_sym_companies
    assert_equal :Companies, 'companies'.to_class_sym
  end

  def test_class_sym_picture
    assert_equal :Picture, 'picture'.to_class_sym
  end

  def test_class_sym_attachments
    assert_equal :Attachments, 'attachments'.to_class_sym
  end

  def test_class_sym_multi_word
    assert_equal :SalesInvoices, 'sales_invoices'.to_class_sym
  end

  # -- Round-trip --

  def test_roundtrip_snake_to_camel_to_snake
    assert_equal 'display_name', 'display_name'.to_camel_case.to_snake_case
  end

  def test_roundtrip_camel_to_snake_to_camel
    assert_equal 'displayName', 'displayName'.to_snake_case.to_camel_case
  end

  # -- BC API fields --

  def test_bc_field_phone_number
    assert_equal 'phone_number', 'phoneNumber'.to_snake_case
  end

  def test_bc_field_balance_due
    assert_equal 'balance_due', 'balanceDue'.to_snake_case
  end

  def test_bc_field_display_name_to_camel
    assert_equal 'displayName', 'display_name'.to_camel_case
  end
end
