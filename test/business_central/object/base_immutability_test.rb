# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/base_immutability_test.rb

class BusinessCentral::Object::BaseImmutabilityTest < Minitest::Test
  def setup
    @company_id = '123456'
    @client = BusinessCentral::Client.new(default_company_id: @company_id)
  end

  def test_method_missing_returns_new_instance
    vendors = @client.vendors
    dimensions = vendors.default_dimensions
    refute_same vendors, dimensions
  end

  def test_original_not_mutated_after_chaining
    vendors = @client.vendors

    stub_request(:get, /defaultDimensions/).to_return(
      status: 200, body: '{"value": []}'
    )
    stub_request(:get, /vendors$/).to_return(
      status: 200, body: '{"value": []}'
    )

    vendors.default_dimensions.all
    vendors.all

    assert_requested(:get, /companies.*vendors$/, times: 1)
  end

  def test_repeated_chaining_does_not_accumulate
    vendors = @client.vendors

    stub_request(:get, /defaultDimensions/).to_return(
      status: 200, body: '{"value": []}'
    )

    vendors.default_dimensions.all
    vendors.default_dimensions.all

    assert_requested(:get, /defaultDimensions/, times: 2)
  end

  def test_parallel_chains_are_independent
    vendors = @client.vendors

    stub_request(:get, /defaultDimensions/).to_return(
      status: 200, body: '{"value": []}'
    )
    stub_request(:get, /purchaseInvoices/).to_return(
      status: 200, body: '{"value": []}'
    )

    vendors.default_dimensions.all
    vendors.purchase_invoices.all

    assert_requested(:get, /defaultDimensions/, times: 1)
    assert_requested(:get, /purchaseInvoices/, times: 1)
  end

  def test_deep_chaining_builds_correct_url
    vendor_id = '456'

    stub_request(:get, %r{vendors\(#{vendor_id}\)/defaultDimensions}).to_return(
      status: 200, body: '{"value": []}'
    )

    @client.vendors(id: vendor_id).default_dimensions.all

    assert_requested(
      :get,
      %r{companies\(#{@company_id}\)/vendors\(#{vendor_id}\)/defaultDimensions}
    )
  end

  def test_object_path_is_frozen
    vendors = @client.vendors

    assert_raises(FrozenError) do
      vendors.instance_variable_get(:@object_path) << { path: 'hack', id: nil }
    end
  end

  def test_chaining_with_concrete_class_returns_correct_type
    companies = @client.companies
    assert_instance_of BusinessCentral::Object::Companies, companies
  end

  def test_chaining_with_unknown_entity_returns_base
    vendors = @client.vendors
    result = vendors.default_dimensions
    assert_instance_of BusinessCentral::Object::Base, result
  end
end
