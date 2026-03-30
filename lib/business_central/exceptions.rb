# frozen_string_literal: true

module BusinessCentral
  class BusinessCentralError < StandardError; end

  class ApiException < BusinessCentralError
  end

  class CompanyNotFoundException < BusinessCentralError
    def message
      'Company not found'
    end
  end

  class UnauthorizedException < BusinessCentralError
    def message
      'Unauthorized - The credentials provided are incorrect'
    end
  end

  class ForbiddenException < BusinessCentralError
    def message
      'Forbidden - Insufficient permissions for this operation'
    end
  end

  class NotFoundException < BusinessCentralError
    def message
      'Not Found - The URL provided cannot be found'
    end
  end

  class ConflictException < BusinessCentralError
  end

  class BadRequestException < BusinessCentralError
  end

  class UnprocessableEntityException < BusinessCentralError
  end

  class RateLimitException < BusinessCentralError
    attr_reader :retry_after

    def initialize(retry_after = nil)
      @retry_after = retry_after
      super("Rate limited by API. Retry after #{retry_after || 'unknown'} seconds")
    end
  end

  class InvalidObjectURLException < BusinessCentralError
    def message
      'Object URL missing for request'
    end
  end

  class InvalidClientException < BusinessCentralError
    def message
      'Invalid client setup'
    end
  end

  class InvalidGrantException < BusinessCentralError
    def initialize(error_message)
      @error_message = error_message
      super
    end

    attr_reader :error_message

    def message
      'The provided grant has expired due to it being revoked, a fresh auth token is needed'
    end
  end
end
