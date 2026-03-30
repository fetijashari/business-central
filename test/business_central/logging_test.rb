# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/logging_test.rb

class BusinessCentral::LoggingTest < Minitest::Test
  def setup
    @log_output = StringIO.new
    @logger = Logger.new(@log_output, level: Logger::DEBUG)
    @company_id = '123'
    @client = BusinessCentral::Client.new(
      default_company_id: @company_id,
      logger: @logger
    )
    @url = "#{@client.url}/companies(#{@company_id})/vendors"
  end

  def test_default_logger_exists
    client = BusinessCentral::Client.new
    assert_instance_of Logger, client.logger
  end

  def test_custom_logger_is_used
    assert_same @logger, @client.logger
  end

  def test_successful_get_is_logged
    stub_request(:get, @url).to_return(status: 200, body: '{"value": []}')

    @client.vendors.find_all

    log = @log_output.string
    assert_match(/BC API.*GET/, log)
    assert_match(/completed/, log)
  end

  def test_failed_request_is_logged
    stub_request(:get, @url).to_return(status: 401, body: '{}')

    assert_raises(BusinessCentral::UnauthorizedException) do
      @client.vendors.find_all
    end

    log = @log_output.string
    assert_match(/failed/, log)
    assert_match(/UnauthorizedException/, log)
  end

  def test_log_does_not_contain_credentials
    client = BusinessCentral::Client.new(
      username: 'admin',
      password: 'supersecret',
      default_company_id: @company_id,
      logger: @logger
    )

    stub_request(:get, /vendors/).to_return(status: 200, body: '{"value": []}')
    client.vendors.find_all

    log = @log_output.string
    refute_includes log, 'admin'
    refute_includes log, 'supersecret'
  end

  def test_log_filters_query_params
    stub_request(:get, /vendors.*filter/).to_return(status: 200, body: '{"value": []}')

    @client.vendors.where("displayName eq '?'", 'Secret Company')

    log = @log_output.string
    refute_includes log, 'Secret Company'
    assert_match(/\[filtered\]/, log)
  end

  def test_log_includes_timing
    stub_request(:get, @url).to_return(status: 200, body: '{"value": []}')

    @client.vendors.find_all

    assert_match(/\d+\.\d+s/, @log_output.string)
  end

  def test_silent_logger_does_not_crash
    client = BusinessCentral::Client.new(
      default_company_id: '123',
      logger: Logger.new(File::NULL)
    )

    stub_request(:get, /vendors/).to_return(status: 200, body: '{"value": []}')
    client.vendors.find_all
  end

  def test_log_includes_http_method
    stub_request(:post, @url).to_return(status: 201, body: '{"displayName": "V"}')

    @client.vendors.create(display_name: 'V')

    assert_match(/POST/, @log_output.string)
  end
end
