# frozen_string_literal: true

require_relative "exceptions"
require_relative "variables"
require_relative "null_logger"
require_relative "headers"
require_relative "response"

require "rest-client"

module ApiAdaptor
  # HTTP client for JSON APIs with comprehensive redirect handling and authentication support.
  #
  # JSONClient provides a low-level interface for making HTTP requests to JSON APIs. It handles
  # automatic JSON parsing, configurable redirect following, authentication (bearer token and basic auth),
  # timeout management, and comprehensive error handling.
  #
  # @example Basic usage with bearer token
  #   client = JSONClient.new(bearer_token: "abc123")
  #   response = client.get_json("https://api.example.com/users")
  #   users = response["data"]
  #
  # @example Custom timeout and redirect configuration
  #   client = JSONClient.new(
  #     timeout: 10,
  #     max_redirects: 5,
  #     follow_non_get_redirects: true
  #   )
  #
  # @example With basic authentication
  #   client = JSONClient.new(
  #     basic_auth: { user: "username", password: "password" }
  #   )
  #
  # @example Disable cross-origin redirects for security
  #   client = JSONClient.new(
  #     allow_cross_origin_redirects: false
  #   )
  #
  # @see Base for a higher-level API client framework
  class JsonClient
    include ApiAdaptor::ExceptionHandling

    # @return [Logger] Logger instance for request/response logging
    # @return [Hash] Client configuration options
    attr_accessor :logger, :options

    # Initializes a new JSON HTTP client
    #
    # @param options [Hash] Configuration options
    # @option options [String] :bearer_token Bearer token for Authorization header
    # @option options [Hash] :basic_auth Basic authentication credentials with :user and :password keys
    # @option options [Integer] :timeout Request timeout in seconds (default: 4)
    # @option options [Integer] :max_redirects Maximum number of redirects to follow (default: 3)
    # @option options [Boolean] :allow_cross_origin_redirects Allow redirects to different origins (default: true)
    # @option options [Boolean] :forward_auth_on_cross_origin_redirects Forward auth headers on cross-origin redirects (default: false, security risk if enabled)
    # @option options [Boolean] :follow_non_get_redirects Follow redirects for POST/PUT/PATCH/DELETE (default: false, only 307/308 supported)
    # @option options [Logger] :logger Custom logger instance (default: NullLogger)
    #
    # @raise [RuntimeError] If disable_timeout or negative timeout is provided
    #
    # @example Default configuration
    #   client = JSONClient.new
    #   # timeout: 4s, max_redirects: 3, only GET/HEAD follow redirects
    #
    # @example Full configuration
    #   client = JSONClient.new(
    #     bearer_token: "secret",
    #     timeout: 10,
    #     max_redirects: 5,
    #     allow_cross_origin_redirects: false,
    #     logger: Logger.new($stdout)
    #   )
    def initialize(options = {})
      raise "It is no longer possible to disable the timeout." if options[:disable_timeout] || options[:timeout].to_i.negative?

      @logger = options[:logger] || NullLogger.new
      @options = options
    end

    # Returns default HTTP headers for all requests
    #
    # @return [Hash] Default headers including Accept and User-Agent
    def self.default_request_headers
      {
        "Accept" => "application/json",
        "User-Agent" => "#{Variables.app_name}/#{Variables.app_version} (#{Variables.app_contact})"
      }
    end

    # Returns default headers for requests with JSON body
    #
    # @return [Hash] Default headers plus Content-Type: application/json
    def self.default_request_with_json_body_headers
      default_request_headers.merge(json_body_headers)
    end

    # Returns Content-Type header for JSON requests
    #
    # @return [Hash] Content-Type header
    def self.json_body_headers
      {
        "Content-Type" => "application/json"
      }
    end

    # Default request timeout in seconds
    DEFAULT_TIMEOUT_IN_SECONDS = 4

    # Default maximum number of redirects to follow
    DEFAULT_MAX_REDIRECTS = 3

    # Performs a GET request and returns the raw response
    #
    # @param url [String] The URL to request
    #
    # @return [RestClient::Response] Raw HTTP response
    #
    # @raise [HTTPClientError, HTTPServerError] On HTTP errors
    # @raise [TimedOutException] On timeout
    # @raise [EndpointNotFound] On connection refused
    # @raise [InvalidUrl] On invalid URI
    # @raise [TooManyRedirects] When max_redirects is exceeded
    # @raise [RedirectLocationMissing] When redirect lacks Location header
    def get_raw!(url)
      do_raw_request(:get, url)
    end

    # Performs a GET request and returns the raw response (alias for get_raw!)
    #
    # @param url [String] The URL to request
    #
    # @return [RestClient::Response] Raw HTTP response
    #
    # @see #get_raw!
    def get_raw(url)
      get_raw!(url)
    end

    # Performs a GET request and parses the JSON response
    #
    # @param url [String] The URL to request
    # @param additional_headers [Hash] Additional HTTP headers to include
    # @yield [response] Optional block to create custom response object
    # @yieldparam response [RestClient::Response] The raw HTTP response
    # @yieldreturn [Object] Custom response object
    #
    # @return [Response, Object] Response object or custom object from block
    #
    # @raise [HTTPClientError, HTTPServerError] On HTTP errors
    # @raise [TimedOutException] On timeout
    #
    # @example Basic usage
    #   response = client.get_json("https://api.example.com/users")
    #   users = response["data"]
    #
    # @example With custom response class
    #   users = client.get_json("https://api.example.com/users") do |r|
    #     UserListResponse.new(r)
    #   end
    def get_json(url, additional_headers = {}, &create_response)
      do_json_request(:get, url, nil, additional_headers, &create_response)
    end

    # Performs a POST request with JSON body
    #
    # @param url [String] The URL to request
    # @param params [Hash] Data to send as JSON in request body (default: {})
    # @param additional_headers [Hash] Additional HTTP headers to include
    #
    # @return [Response] Response object with parsed JSON
    #
    # @raise [HTTPClientError, HTTPServerError] On HTTP errors
    #
    # @example
    #   response = client.post_json("https://api.example.com/users", {
    #     name: "Alice",
    #     email: "alice@example.com"
    #   })
    def post_json(url, params = {}, additional_headers = {})
      do_json_request(:post, url, params, additional_headers)
    end

    # Performs a PUT request with JSON body
    #
    # @param url [String] The URL to request
    # @param params [Hash] Data to send as JSON in request body
    # @param additional_headers [Hash] Additional HTTP headers to include
    #
    # @return [Response] Response object with parsed JSON
    #
    # @raise [HTTPClientError, HTTPServerError] On HTTP errors
    def put_json(url, params, additional_headers = {})
      do_json_request(:put, url, params, additional_headers)
    end

    # Performs a PATCH request with JSON body
    #
    # @param url [String] The URL to request
    # @param params [Hash] Data to send as JSON in request body
    # @param additional_headers [Hash] Additional HTTP headers to include
    #
    # @return [Response] Response object with parsed JSON
    #
    # @raise [HTTPClientError, HTTPServerError] On HTTP errors
    def patch_json(url, params, additional_headers = {})
      do_json_request(:patch, url, params, additional_headers)
    end

    # Performs a DELETE request with optional JSON body
    #
    # @param url [String] The URL to request
    # @param params [Hash] Optional data to send as JSON in request body (default: {})
    # @param additional_headers [Hash] Additional HTTP headers to include
    #
    # @return [Response] Response object with parsed JSON
    #
    # @raise [HTTPClientError, HTTPServerError] On HTTP errors
    def delete_json(url, params = {}, additional_headers = {})
      do_json_request(:delete, url, params, additional_headers)
    end

    # Performs a POST request with multipart/form-data
    #
    # @param url [String] The URL to request
    # @param params [Hash] Multipart form data (may include file uploads)
    #
    # @return [Response] Response object
    #
    # @example Uploading a file
    #   client.post_multipart("https://api.example.com/upload", {
    #     file: File.open("image.jpg", "rb"),
    #     description: "Profile photo"
    #   })
    def post_multipart(url, params)
      r = do_raw_request(:post, url, params.merge(multipart: true))
      Response.new(r)
    end

    # Performs a PUT request with multipart/form-data
    #
    # @param url [String] The URL to request
    # @param params [Hash] Multipart form data (may include file uploads)
    #
    # @return [Response] Response object
    def put_multipart(url, params)
      r = do_raw_request(:put, url, params.merge(multipart: true))
      Response.new(r)
    end

    private

    def do_raw_request(method, url, params = nil)
      do_request(method, url, params)
    rescue RestClient::Exception => e
      raise build_specific_http_error(e, url, nil)
    end

    # method: the symbolic name of the method to use, e.g. :get, :post
    # url:    the request URL
    # params: the data to send (JSON-serialised) in the request body
    # additional_headers: headers to set on the request (in addition to the default ones)
    # create_response: optional block to instantiate a custom response object
    #                  from the Net::HTTPResponse
    def do_json_request(method, url, params = nil, additional_headers = {}, &create_response)
      begin
        additional_headers.merge!(self.class.json_body_headers) if params
        response = do_request(method, url, (params.to_json if params), additional_headers)
      rescue RestClient::Exception => e
        # Attempt to parse the body as JSON if possible
        error_details = begin
          e.http_body ? JSON.parse(e.http_body) : nil
        rescue JSON::ParserError
          nil
        end
        raise build_specific_http_error(e, url, error_details)
      end

      # If no custom response is given, just instantiate Response
      create_response ||= proc { |r| Response.new(r) }
      create_response.call(response)
    end

    # Take a hash of parameters for Request#execute; return a hash of
    # parameters with authentication information included
    def with_auth_options(method_params)
      if @options[:bearer_token]
        headers = method_params[:headers] || {}
        method_params.merge(headers: headers.merge(
          "Authorization" => "Bearer #{@options[:bearer_token]}"
        ))
      elsif @options[:basic_auth]
        method_params.merge(
          user: @options[:basic_auth][:user],
          password: @options[:basic_auth][:password]
        )
      else
        method_params
      end
    end

    # Take a hash of parameters for Request#execute; return a hash of
    # parameters with timeouts included
    def with_timeout(method_params)
      method_params.merge(
        timeout: options[:timeout] || DEFAULT_TIMEOUT_IN_SECONDS,
        open_timeout: options[:timeout] || DEFAULT_TIMEOUT_IN_SECONDS
      )
    end

    def with_headers(method_params, default_headers, additional_headers)
      method_params.merge(
        headers: default_headers
          .merge(method_params[:headers] || {})
          .merge(ApiAdaptor::Headers.headers)
          .merge(additional_headers)
      )
    end

    def with_ssl_options(method_params)
      method_params.merge(
        # This is the default value anyway, but we should probably be explicit
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      )
    end

    def max_redirects
      value = options.fetch(:max_redirects, DEFAULT_MAX_REDIRECTS)
      value = value.to_i
      value.negative? ? 0 : value
    end

    def follow_non_get_redirects?
      options.fetch(:follow_non_get_redirects, false)
    end

    def allow_cross_origin_redirects?
      options.fetch(:allow_cross_origin_redirects, true)
    end

    def forward_auth_on_cross_origin_redirects?
      options.fetch(:forward_auth_on_cross_origin_redirects, false)
    end

    def redirect_status_code?(code)
      code.to_i >= 300 && code.to_i <= 399
    end

    def follow_redirect_code?(method, code)
      code = code.to_i
      return false unless redirect_status_code?(code)
      return false if code == 304
      return false if [305, 306].include?(code)

      if %i[get head].include?(method)
        [301, 302, 303, 307, 308].include?(code)
      else
        return true if follow_non_get_redirects? && [307, 308].include?(code)

        false
      end
    end

    def response_location(response)
      return nil unless response

      headers = response.headers || {}
      headers[:location] || headers["location"] || headers["Location"]
    end

    def resolve_location(current_url, location)
      URI.join(current_url, location.to_s).to_s
    rescue URI::Error
      location.to_s
    end

    def origin_for(url)
      uri = URI.parse(url)
      [uri.scheme, uri.host, uri.port]
    end

    def do_request(method, url, params = nil, additional_headers = {})
      current_method = method
      current_url = url
      current_params = params
      redirects_followed = 0

      initial_origin = begin
        origin_for(url)
      rescue URI::InvalidURIError => e
        raise ApiAdaptor::InvalidUrl, e.message
      end

      loop do
        loggable = { request_uri: current_url, start_time: Time.now.to_f }
        start_logging = loggable.merge(action: "start")
        logger.debug start_logging.to_json

        method_params = {
          method: current_method,
          url: current_url,
          max_redirects: 0
        }
        method_params[:payload] = current_params
        method_params = with_timeout(method_params)
        method_params = with_headers(method_params, self.class.default_request_headers, additional_headers)

        begin
          current_origin = origin_for(current_url)
          cross_origin = current_origin != initial_origin
          include_auth = !cross_origin || forward_auth_on_cross_origin_redirects?
          method_params = with_auth_options(method_params) if include_auth
          unless include_auth
            if method_params[:headers]
              method_params[:headers].delete("Authorization")
              method_params[:headers].delete("Proxy-Authorization")
            end
            method_params.delete(:user)
            method_params.delete(:password)
          end

          method_params = with_ssl_options(method_params) if URI.parse(current_url).is_a? URI::HTTPS
          return ::RestClient::Request.execute(method_params)
        rescue RestClient::ExceptionWithResponse => e
          if e.is_a?(RestClient::Exceptions::Timeout)
            logger.error loggable.merge(status: "timeout", error_message: e.message, error_class: e.class.name,
                                        end_time: Time.now.to_f).to_json
            raise ApiAdaptor::TimedOutException, e.message
          end

          status_code = (e.http_code || e.response&.code).to_i

          raise ApiAdaptor::TimedOutException, e.message if status_code == 408

          if follow_redirect_code?(current_method.to_sym, status_code)
            location = response_location(e.response)
            raise ApiAdaptor::RedirectLocationMissing, "Redirect response missing Location header for #{current_url}" if location.to_s.strip.empty?

            next_url = resolve_location(current_url, location)
            begin
              next_origin = origin_for(next_url)
            rescue URI::InvalidURIError => e
              logger.error loggable.merge(status: "invalid_uri", error_message: e.message, error_class: e.class.name,
                                          end_time: Time.now.to_f).to_json
              raise ApiAdaptor::InvalidUrl, e.message
            end
            if next_origin != initial_origin && !allow_cross_origin_redirects?
              loggable.merge!(status: status_code, end_time: Time.now.to_f, body: e.http_body)
              logger.warn loggable.to_json
              raise
            end

            raise ApiAdaptor::TooManyRedirects, "Too many redirects (max #{max_redirects}) while requesting #{url}" if redirects_followed >= max_redirects

            redirects_followed += 1
            current_url = next_url

            next
          end

          loggable.merge!(status: status_code, end_time: Time.now.to_f, body: e.http_body)
          logger.warn loggable.to_json
          raise
        rescue Errno::ECONNREFUSED => e
          logger.error loggable.merge(status: "refused", error_message: e.message, error_class: e.class.name,
                                      end_time: Time.now.to_f).to_json
          raise ApiAdaptor::EndpointNotFound, "Could not connect to #{current_url}"
        rescue Timeout::Error => e
          logger.error loggable.merge(status: "timeout", error_message: e.message, error_class: e.class.name,
                                      end_time: Time.now.to_f).to_json
          raise ApiAdaptor::TimedOutException, e.message
        rescue RestClient::Exceptions::Timeout => e
          logger.error loggable.merge(status: "timeout", error_message: e.message, error_class: e.class.name,
                                      end_time: Time.now.to_f).to_json
          raise ApiAdaptor::TimedOutException, e.message
        rescue URI::InvalidURIError => e
          logger.error loggable.merge(status: "invalid_uri", error_message: e.message, error_class: e.class.name,
                                      end_time: Time.now.to_f).to_json
          raise ApiAdaptor::InvalidUrl, e.message
        rescue RestClient::Exception => e
          loggable.merge!(status: e.http_code, end_time: Time.now.to_f, body: e.http_body)
          logger.warn loggable.to_json
          raise
        rescue Errno::ECONNRESET => e
          logger.error loggable.merge(status: "connection_reset", error_message: e.message, error_class: e.class.name,
                                      end_time: Time.now.to_f).to_json
          raise ApiAdaptor::TimedOutException, e.message
        rescue SocketError => e
          logger.error loggable.merge(status: "socket_error", error_message: e.message, error_class: e.class.name,
                                      end_time: Time.now.to_f).to_json
          raise ApiAdaptor::SocketErrorException, e.message
        end
      end
    end
  end
end
