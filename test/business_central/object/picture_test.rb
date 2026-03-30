# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/picture_test.rb

class BusinessCentral::Object::PictureTest < Minitest::Test
  def setup
    @company_id = '123456'
    @client = BusinessCentral::Client.new
    @picture = @client.items(id: 123, company_id: @company_id).picture
  end

  def test_find_all
    stub_request(:get, %r{companies\(#{@company_id}\)/items\(123\)/picture})
      .to_return(
        status: 200,
        body: {
          value: [
            {
              id: 112,
              width: 500,
              height: 496,
              contentType: 'image\jpeg'
            }
          ]
        }.to_json
      )
    response = @picture.find_all
    assert_equal 'image\jpeg', response.first[:content_type]
  end

  def test_update_uses_find_by_id
    test_id = 1
    test_etag = 'W/"pic-etag"'

    stub_request(:get, %r{companies\(#{@company_id}\)/items\(123\)/picture\(#{test_id}\)})
      .to_return(
        status: 200,
        body: {
          '@odata.etag': test_etag,
          id: test_id,
          contentType: 'image\jpeg'
        }.to_json
      )

    stub_request(:patch, %r{companies\(#{@company_id}\)/items\(123\)/picture\(#{test_id}\)/content})
      .to_return(status: 204)

    response = @picture.update(test_id, 'ImageData')
    assert response

    # Verify it called find_by_id (GET with ID), not find_all (GET collection)
    assert_requested(:get, /picture\(#{test_id}\)/, times: 1)
  end

  def test_update_sends_correct_etag
    test_id = 1
    test_etag = 'W/"correct-pic-etag"'

    stub_request(:get, /picture\(#{test_id}\)/)
      .to_return(
        status: 200,
        body: { '@odata.etag': test_etag, id: test_id }.to_json
      )

    stub_request(:patch, %r{picture\(#{test_id}\)/content})
      .to_return(status: 204)

    @picture.update(test_id, 'ImageData')

    assert_requested(:patch, /content/) do |req|
      assert_equal test_etag, req.headers['If-Match']
    end
  end

  def test_update_sends_octet_stream_content_type
    test_id = 1

    stub_request(:get, /picture\(#{test_id}\)/)
      .to_return(
        status: 200,
        body: { '@odata.etag': 'W/"etag"', id: test_id }.to_json
      )

    stub_request(:patch, /content/).to_return(status: 204)

    @picture.update(test_id, 'ImageData')

    assert_requested(:patch, /content/) do |req|
      assert_equal 'application/octet-stream', req.headers['Content-Type']
    end
  end

  def test_delete
    test_id = 2
    stub_request(:get, %r{companies\(#{@company_id}\)/items\(123\)/picture\(#{test_id}\)})
      .to_return(
        status: 200,
        body: {
          '@odata.etag': '113',
          contentType: 'image\jpeg'
        }.to_json
      )

    stub_request(:delete, %r{companies\(#{@company_id}\)/items\(123\)/picture\(#{test_id}\)})
      .to_return(status: 204)

    assert @picture.destroy(test_id)
  end
end
