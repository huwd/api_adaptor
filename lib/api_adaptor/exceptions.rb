# frozen_string_literal: true

module ApiAdaptor
  # Abstract error class
  class BaseError < StandardError; end

  class TooManyRedirects < BaseError; end

  class RedirectLocationMissing < BaseError; end

  class EndpointNotFound < BaseError; end

  class TimedOutException < BaseError; end

  class InvalidUrl < BaseError; end

  class SocketErrorException < BaseError; end

  # Superclass for all 4XX and 5XX errors
  class HTTPErrorResponse < BaseError
    attr_accessor :code, :error_details, :http_body

    def initialize(code, message = nil, error_details = nil, http_body = nil)
      super(message)
      @code = code
      @error_details = error_details
      @http_body = http_body
    end
  end

  # Superclass & fallback for all 4XX errors
  class HTTPClientError < HTTPErrorResponse; end

  class HTTPIntermittentClientError < HTTPClientError; end

  class HTTPNotFound < HTTPClientError; end

  class HTTPGone < HTTPClientError; end

  class HTTPPayloadTooLarge < HTTPClientError; end

  class HTTPUnauthorized < HTTPClientError; end

  class HTTPForbidden < HTTPClientError; end

  class HTTPConflict < HTTPClientError; end

  class HTTPUnprocessableEntity < HTTPClientError; end

  class HTTPUnprocessableContent < HTTPClientError; end

  class HTTPBadRequest < HTTPClientError; end

  class HTTPTooManyRequests < HTTPIntermittentClientError; end

  # Superclass & fallback for all 5XX errors
  class HTTPServerError < HTTPErrorResponse; end

  class HTTPIntermittentServerError < HTTPServerError; end

  class HTTPInternalServerError < HTTPServerError; end

  class HTTPBadGateway < HTTPIntermittentServerError; end

  class HTTPUnavailable < HTTPIntermittentServerError; end

  class HTTPGatewayTimeout < HTTPIntermittentServerError; end

  module ExceptionHandling
    def build_specific_http_error(error, url, details = nil)
      message = "URL: #{url}\nResponse body:\n#{error.http_body}"
      code = error.http_code
      error_class_for_code(code).new(code, message, details, error.http_body)
    end

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
