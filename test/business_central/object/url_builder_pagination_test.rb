# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/url_builder_pagination_test.rb

class BusinessCentral::Object::URLBuilderPaginationTest < Minitest::Test
  def test_build_with_top
    url = BusinessCentral::Object::URLBuilder.new(
      base_url: 'https://api.example.com', top: 10
    ).build
    assert_includes url, '$top=10'
  end

  def test_build_with_skip
    url = BusinessCentral::Object::URLBuilder.new(
      base_url: 'https://api.example.com', skip: 20
    ).build
    assert_includes url, '$skip=20'
  end

  def test_build_with_order_by
    url = BusinessCentral::Object::URLBuilder.new(
      base_url: 'https://api.example.com', order_by: 'displayName asc'
    ).build
    assert_includes url, '$orderby=displayName asc'
  end

  def test_build_with_select
    url = BusinessCentral::Object::URLBuilder.new(
      base_url: 'https://api.example.com', select: 'id,displayName'
    ).build
    assert_includes url, '$select=id,displayName'
  end

  def test_build_with_expand
    url = BusinessCentral::Object::URLBuilder.new(
      base_url: 'https://api.example.com', expand: 'defaultDimensions'
    ).build
    assert_includes url, '$expand=defaultDimensions'
  end

  def test_build_with_filter_and_top
    url = BusinessCentral::Object::URLBuilder.new(
      base_url: 'https://api.example.com',
      filter: 'displayName+eq+%27Test%27',
      top: 5
    ).build
    assert_includes url, '$filter='
    assert_includes url, '$top=5'
    assert_includes url, '&'
  end

  def test_build_with_all_params
    url = BusinessCentral::Object::URLBuilder.new(
      base_url: 'https://api.example.com',
      filter: 'name+eq+%27X%27',
      top: 10,
      skip: 20,
      order_by: 'name',
      select: 'id,name',
      expand: 'lines'
    ).build
    assert_includes url, '$filter='
    assert_includes url, '$top=10'
    assert_includes url, '$skip=20'
    assert_includes url, '$orderby=name'
    assert_includes url, '$select=id,name'
    assert_includes url, '$expand=lines'
  end

  def test_build_with_no_params_has_no_query_string
    url = BusinessCentral::Object::URLBuilder.new(
      base_url: 'https://api.example.com'
    ).build
    refute_includes url, '?'
  end

  def test_query_string_starts_with_question_mark
    url = BusinessCentral::Object::URLBuilder.new(
      base_url: 'https://api.example.com', top: 5
    ).build
    assert_match(/\?\$top=5/, url)
  end

  def test_multiple_params_joined_with_ampersand
    url = BusinessCentral::Object::URLBuilder.new(
      base_url: 'https://api.example.com', top: 5, skip: 10
    ).build
    assert_match(/\$top=5&\$skip=10/, url)
  end
end
