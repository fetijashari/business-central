# frozen_string_literal: true

require 'test_helper'
# rake test TEST=test/business_central/object/attachments_test.rb

class BusinessCentral::Object::AttachmentsTest < Minitest::Test
  def setup
    @company_id = '123456'
    @client = BusinessCentral::Client.new
    @attachment = @client.attachments(company_id: @company_id)
  end

  def test_find_all
    stub_request(:get, /attachments/)
      .to_return(
        status: 200,
        body: {
          value: [
            {
              id: '111',
              fileName: 'attachment1.pdf'
            }
          ]
        }.to_json
      )

    response = @attachment.find_all
    assert_equal 'attachment1.pdf', response.first[:file_name]
  end

  def test_find_by_id
    test_id = '09876'
    stub_request(:get, /attachments\(#{test_id}\)/)
      .to_return(
        status: 200,
        body: {
          id: '222',
          fileName: 'attachment2.jpg'
        }.to_json
      )

    response = @attachment.find_by_id(test_id)
    assert_equal 'attachment2.jpg', response[:file_name]
  end

  def test_where
    test_filter = "fileName eq 'attachment3.png'"
    stub_request(:get, /attachments\?\$filter=#{test_filter}/)
      .to_return(
        status: 200,
        body: {
          value: [
            {
              id: '333',
              fileName: 'attachment3.png'
            }
          ]
        }.to_json
      )

    response = @attachment.where(test_filter)
    assert_equal 'attachment3.png', response.first[:file_name]
  end

  def test_create
    stub_request(:post, /attachments/)
      .to_return(
        status: 200,
        body: {
          fileName: 'attachment4.gif'
        }.to_json
      )

    response = @attachment.create(
      file_name: 'attachment4.gif'
    )
    assert_equal 'attachment4.gif', response[:file_name]
  end

  def test_update_fetches_etag_before_patching
    test_parent_id = '011123'
    test_attachment_id = '11123'
    test_etag = 'W/"etag-112"'

    stub_request(:get, /attachments\(#{test_attachment_id}\)/)
      .to_return(
        status: 200,
        body: {
          '@odata.etag': test_etag,
          id: test_attachment_id,
          fileName: 'attachment5.pdf'
        }.to_json
      )

    stub_request(:patch, /attachments\(parentId=#{test_parent_id},id=#{test_attachment_id}\)/)
      .to_return(status: 204)

    @attachment.update(
      parent_id: test_parent_id,
      attachment_id: test_attachment_id,
      content: 'file bytes'
    )

    assert_requested(:get, /attachments\(#{test_attachment_id}\)/, times: 1)
    assert_requested(:patch, /content/, times: 1)
  end

  def test_update_sends_correct_etag
    test_parent_id = '011123'
    test_attachment_id = '11123'
    test_etag = 'W/"correct-etag"'

    stub_request(:get, /attachments\(#{test_attachment_id}\)/)
      .to_return(
        status: 200,
        body: { '@odata.etag': test_etag, id: test_attachment_id }.to_json
      )

    stub_request(:patch, /content/).to_return(status: 204)

    @attachment.update(
      parent_id: test_parent_id,
      attachment_id: test_attachment_id,
      content: 'data'
    )

    assert_requested(:patch, /content/) do |req|
      assert_equal test_etag, req.headers['If-Match']
    end
  end

  def test_update_sends_octet_stream_content_type
    test_parent_id = '011123'
    test_attachment_id = '11123'

    stub_request(:get, /attachments\(#{test_attachment_id}\)/)
      .to_return(
        status: 200,
        body: { '@odata.etag': 'W/"etag"', id: test_attachment_id }.to_json
      )

    stub_request(:patch, /content/).to_return(status: 204)

    @attachment.update(
      parent_id: test_parent_id,
      attachment_id: test_attachment_id,
      content: 'data'
    )

    assert_requested(:patch, /content/) do |req|
      assert_equal 'application/octet-stream', req.headers['Content-Type']
    end
  end

  def test_delete_fetches_etag_before_deleting
    test_attachment_id = '11124'
    test_etag = 'W/"delete-etag"'

    stub_request(:get, /attachments\(#{test_attachment_id}\)/)
      .to_return(
        status: 200,
        body: { '@odata.etag': test_etag, id: test_attachment_id }.to_json
      )

    stub_request(:delete, /attachments\(#{test_attachment_id}\)/)
      .to_return(status: 204)

    assert @attachment.destroy(test_attachment_id)
    assert_requested(:get, /attachments\(#{test_attachment_id}\)/, times: 1)
  end

  def test_delete_sends_correct_etag
    test_attachment_id = '11124'
    test_etag = 'W/"specific-etag"'

    stub_request(:get, /attachments\(#{test_attachment_id}\)/)
      .to_return(
        status: 200,
        body: { '@odata.etag': test_etag, id: test_attachment_id }.to_json
      )

    stub_request(:delete, /attachments\(#{test_attachment_id}\)/)
      .to_return(status: 204)

    @attachment.destroy(test_attachment_id)

    assert_requested(:delete, /attachments/) do |req|
      assert_equal test_etag, req.headers['If-Match']
    end
  end
end
