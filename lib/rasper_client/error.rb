module RasperClient
  class Error < ::RuntimeError
    INVALID_CREDENTIALS = 'Invalid credentials'.freeze

    class << self
      def invalid_credentials
        new(INVALID_CREDENTIALS)
      end
    end
  end
end
