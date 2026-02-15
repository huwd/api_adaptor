# frozen_string_literal: true

module ApiAdaptor
  # Base exception class for all ApiAdaptor errors
  class BaseError < StandardError; end

  # Raised when too many redirects are followed
  #
  # @see JSONClient#max_redirects
  class TooManyRedirects < BaseError; end

  # Raised when a redirect response is missing the Location header
  class RedirectLocationMissing < BaseError; end

  # Raised when connection to the endpoint is refused (ECONNREFUSED)
  class EndpointNotFound < BaseError; end

  # Raised when a request times out
  #
  # @see JSONClient#initialize for timeout configuration
  class TimedOutException < BaseError; end

  # Raised when an invalid URL is provided
  class InvalidUrl < BaseError; end

  # Raised when a socket error occurs during the request
  class SocketErrorException < BaseError; end

  # Base class for all HTTP 4xx and 5xx error responses
  #
  # Provides access to the HTTP status code, error details, and response body.
  #
  # @example Handling HTTP errors
  #   begin
  #     client.get_json(url)
  #   rescue ApiAdaptor::HTTPNotFound => e
  #     puts "Resource not found: #{e.code}"
  #   rescue ApiAdaptor::HTTPServerError => e
  #     puts "Server error: #{e.code} - #{e.error_details}"
  #   end
  class HTTPErrorResponse < BaseError
    # @return [Integer] HTTP status code
    # @return [Hash, nil] Parsed error details from response body
    # @return [String, nil] Raw HTTP response body
    attr_accessor :code, :error_details, :http_body

    # Initializes a new HTTP error response
    #
    # @param code [Integer] HTTP status code
    # @param message [String, nil] Error message
    # @param error_details [Hash, nil] Parsed error details from JSON body
    # @param http_body [String, nil] Raw HTTP response body
    def initialize(code, message = nil, error_details = nil, http_body = nil)
      super(message)
      @code = code
      @error_details = error_details
      @http_body = http_body
    end
  end

  # Base class for all HTTP 4xx client errors
  class HTTPClientError < HTTPErrorResponse; end

  # Base class for intermittent client errors that may succeed on retry
  class HTTPIntermittentClientError < HTTPClientError; end

  # Raised on HTTP 404 Not Found
  class HTTPNotFound < HTTPClientError; end

  # Raised on HTTP 410 Gone
  class HTTPGone < HTTPClientError; end

  # Raised on HTTP 413 Payload Too Large
  class HTTPPayloadTooLarge < HTTPClientError; end

  # Raised on HTTP 401 Unauthorized
  class HTTPUnauthorized < HTTPClientError; end

  # Raised on HTTP 403 Forbidden
  class HTTPForbidden < HTTPClientError; end

  # Raised on HTTP 409 Conflict
  class HTTPConflict < HTTPClientError; end

  # Raised on HTTP 422 Unprocessable Entity
  class HTTPUnprocessableEntity < HTTPClientError; end

  # Raised on HTTP 422 Unprocessable Content (alternative name)
  class HTTPUnprocessableContent < HTTPClientError; end

  # Raised on HTTP 400 Bad Request
  class HTTPBadRequest < HTTPClientError; end

  # Raised on HTTP 429 Too Many Requests
  class HTTPTooManyRequests < HTTPIntermittentClientError; end

  # Base class for all HTTP 5xx server errors
  class HTTPServerError < HTTPErrorResponse; end

  # Base class for intermittent server errors that may succeed on retry
  class HTTPIntermittentServerError < HTTPServerError; end

  # Raised on HTTP 500 Internal Server Error
  class HTTPInternalServerError < HTTPServerError; end

  # Raised on HTTP 502 Bad Gateway
  class HTTPBadGateway < HTTPIntermittentServerError; end

  # Raised on HTTP 503 Service Unavailable
  class HTTPUnavailable < HTTPIntermittentServerError; end

  # Raised on HTTP 504 Gateway Timeout
  class HTTPGatewayTimeout < HTTPIntermittentServerError; end

  # Module providing HTTP error handling and exception mapping
  module ExceptionHandling
    # Builds a specific HTTP error exception based on the status code
    #
    # @param error [RestClient::Exception] The RestClient exception
    # @param url [String] The URL that was requested
    # @param details [Hash, nil] Parsed error details from JSON response
    #
    # @return [HTTPErrorResponse] Specific exception instance
    #
    # @api private
    def build_specific_http_error(error, url, details = nil)
      message = "URL: #{url}\nResponse body:\n#{error.http_body}"
      code = error.http_code
      error_class_for_code(code).new(code, message, details, error.http_body)
    end

    # Maps HTTP status codes to exception classes
    #
    # @param code [Integer] HTTP status code
    #
    # @return [Class] Exception class for the status code
    #
    # @api private
    def error_class_for_code(code)
      case code
      when 400
        ApiAdaptor::HTTPBadRequest
      when 401
        ApiAdaptor::HTTPUnauthorized
      when 403
        ApiAdaptor::HTTPForbidden
      when 404
        ApiAdaptor::HTTPNotFound
      when 409
        ApiAdaptor::HTTPConflict
      when 410
        ApiAdaptor::HTTPGone
      when 413
        ApiAdaptor::HTTPPayloadTooLarge
      when 422
        ApiAdaptor::HTTPUnprocessableEntity
      when 429
        ApiAdaptor::HTTPTooManyRequests
      when (400..499)
        ApiAdaptor::HTTPClientError
      when 500
        ApiAdaptor::HTTPInternalServerError
      when 502
        ApiAdaptor::HTTPBadGateway
      when 503
        ApiAdaptor::HTTPUnavailable
      when 504
        ApiAdaptor::HTTPGatewayTimeout
      when (500..599)
        ApiAdaptor::HTTPServerError
      else
        ApiAdaptor::HTTPErrorResponse
      end
    end
  end
end
