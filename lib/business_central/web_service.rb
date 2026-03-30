# frozen_string_literal: true

module BusinessCentral
  class WebService
    using Refinements::Strings

    DEFAULT_URL = 'https://api.businesscentral.dynamics.com/v2.0/production/ODataV4'

    attr_reader :url, :object_url

    def initialize(client:, url: nil, object_url: nil)
      @client = client
      @url = url || client.web_service_url || DEFAULT_URL
      @object_url = object_url
    end

    def object(object_url = '', *values)
      resolved = if values.empty?
                   object_url
                 else
                   Object::URLBuilder.sanitize(object_url, values)
                 end

      self.class.new(client: @client, url: @url, object_url: resolved)
    end

    def get(query = '', *values)
      raise InvalidObjectURLException if @object_url.to_s.blank?

      Object::Request.get(
        @client,
        build_url(
          filter: Object::FilterQuery.sanitize(query, values)
        )
      )
    end

    def post(params = {})
      raise InvalidObjectURLException if @object_url.to_s.blank?

      Object::Request.post(
        @client,
        build_url,
        params
      )
    end

    def patch(params = {}, etag: nil)
      raise InvalidObjectURLException if @object_url.to_s.blank?

      unless etag
        result = get
        etag = result[:etag]
      end
      Object::Request.patch(
        @client,
        build_url,
        etag,
        params
      )
    end

    def delete(etag: nil)
      raise InvalidObjectURLException if @object_url.to_s.blank?

      unless etag
        result = get
        etag = result[:etag]
      end
      Object::Request.delete(
        @client,
        build_url,
        etag
      )
    end

    private

    def build_url(filter: '')
      Object::URLBuilder.new(
        base_url: "#{@url}/#{@object_url}",
        filter:
      ).build
    end
  end
end
