# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/method_missing_test.rb

class BusinessCentral::Object::MethodMissingTest < Minitest::Test
  def setup
    @log_output = StringIO.new
    @logger = Logger.new(@log_output, level: Logger::DEBUG)
    @client = BusinessCentral::Client.new(
      default_company_id: '123',
      logger: @logger
    )
  end

  # -- Known entities --

  def test_known_entity_does_not_warn
    stub_request(:get, /vendors/).to_return(status: 200, body: '{"value": []}')
    @client.vendors.find_all
    refute_match(/unregistered/, @log_output.string)
  end

  def test_responds_to_known_entities
    assert @client.respond_to?(:vendors)
    assert @client.respond_to?(:customers)
    assert @client.respond_to?(:items)
    assert @client.respond_to?(:sales_invoices)
    assert @client.respond_to?(:purchase_invoices)
  end

  def test_responds_to_concrete_classes
    assert @client.respond_to?(:companies)
    assert @client.respond_to?(:attachments)
  end

  # -- Unknown entities --

  def test_unknown_entity_logs_warning
    stub_request(:get, /vendores/).to_return(status: 200, body: '{"value": []}')
    @client.vendores.find_all
    assert_match(/unregistered.*vendores/, @log_output.string)
  end

  def test_unknown_entity_still_works
    stub_request(:get, /customEntity/).to_return(status: 200, body: '{"value": []}')
    result = @client.custom_entity.find_all
    assert_equal [], result
  end

  def test_respond_to_false_for_unknown
    refute @client.respond_to?(:vendores)
    refute @client.respond_to?(:totally_fake)
  end

  # -- Chained unknown entities --

  def test_chained_unknown_entity_warns
    stub_request(:get, /vendors.*fakeRelation/).to_return(status: 200, body: '{"value": []}')
    @client.vendors(id: '456').fake_relation.find_all
    assert_match(/unregistered.*fake_relation/, @log_output.string)
  end

  def test_chained_known_entity_does_not_warn
    stub_request(:get, /vendors.*defaultDimensions/).to_return(status: 200, body: '{"value": []}')
    @client.vendors(id: '456').default_dimensions.find_all
    refute_match(/unregistered/, @log_output.string)
  end

  # -- Constants --

  def test_known_entities_is_frozen
    assert BusinessCentral::KNOWN_BC_ENTITIES.frozen?
  end

  def test_known_entities_contains_core_resources
    entities = BusinessCentral::KNOWN_BC_ENTITIES
    %w[vendors customers items sales_invoices purchase_invoices
       default_dimensions picture attachments].each do |entity|
      assert_includes entities, entity
    end
  end
end
