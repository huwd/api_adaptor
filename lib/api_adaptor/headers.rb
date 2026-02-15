# frozen_string_literal: true

module ApiAdaptor
  # Thread-safe header management for HTTP requests
  #
  # Headers are stored in thread-local storage, allowing different threads
  # to maintain separate header contexts without interference.
  #
  # @example Setting custom headers
  #   ApiAdaptor::Headers.set_header("X-Request-ID", "12345")
  #   ApiAdaptor::Headers.set_header("X-Correlation-ID", "abcde")
  #
  # @example Getting all headers
  #   headers = ApiAdaptor::Headers.headers
  #   # => {"X-Request-ID" => "12345", "X-Correlation-ID" => "abcde"}
  #
  # @example Clearing headers
  #   ApiAdaptor::Headers.clear_headers
  class Headers
    class << self
      # Sets a header value for the current thread
      #
      # @param header_name [String] Header name
      # @param value [String] Header value
      #
      # @return [String] The value that was set
      def set_header(header_name, value)
        header_data[header_name] = value
      end

      # Returns all non-empty headers for the current thread
      #
      # @return [Hash] Hash of header names to values, excluding nil/empty values
      def headers
        header_data.reject { |_k, v| v.nil? || v.empty? }
      end

      # Clears all headers for the current thread
      #
      # @return [Hash] Empty hash
      def clear_headers
        Thread.current[:headers] = {}
      end

      private

      # Returns the thread-local header storage
      #
      # @return [Hash] Thread-local header hash
      #
      # @api private
      def header_data
        Thread.current[:headers] ||= {}
      end
    end
  end
end
