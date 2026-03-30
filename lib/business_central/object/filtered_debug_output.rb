# frozen_string_literal: true

module BusinessCentral
  module Object
    class FilteredDebugOutput
      SENSITIVE_PATTERN = /(Authorization|Cookie|Set-Cookie|X-Api-Key):\s*[^\r\n]+/i
      REDACTED = '[REDACTED]'

      def initialize(output = $stdout)
        @output = output
      end

      def <<(message)
        @output << filter_sensitive_data(message.to_s)
      end

      def print(message)
        self << message
      end

      private

      def filter_sensitive_data(message)
        message.gsub(SENSITIVE_PATTERN) do |match|
          header_name = match.split(':').first
          "#{header_name}: #{REDACTED}"
        end
      end
    end
  end
end
