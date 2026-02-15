# frozen_string_literal: true

require_relative "json_client"
require "cgi"
require_relative "null_logger"
require_relative "list_response"

module ApiAdaptor
  # Base class for building API-specific clients.
  #
  # Provides common functionality for JSON API clients including HTTP method delegation,
  # URL construction, and pagination support. Subclass this to create clients for specific APIs.
  #
  # @example Creating a custom API client
  #   class MyApiClient < ApiAdaptor::Base
  #     def initialize
  #       super("https://api.example.com", bearer_token: "abc123")
  #     end
  #
  #     def get_user(id)
  #       get_json("/users/#{id}")
  #     end
  #
  #     def list_posts(page: 1)
  #       get_list("/posts?page=#{page}")
  #     end
  #   end
  #
  # @example Using default options
  #   ApiAdaptor::Base.default_options = { timeout: 10 }
  #   client = MyApiClient.new  # Inherits 10-second timeout
  #
  # @see JSONClient for underlying HTTP client options
  class Base
    # Raised when an invalid API URL is provided
    class InvalidAPIURL < StandardError
    end

    extend Forwardable

    # Returns the underlying JSONClient instance, creating it if necessary
    #
    # @return [JSONClient] The HTTP client instance
    def client
      @client ||= create_client
    end

    # Creates a new JSONClient with the configured options
    #
    # @return [JSONClient] A new HTTP client instance
    def create_client
      ApiAdaptor::JsonClient.new(options)
    end

    # @!method get_json(url, &block)
    #   Performs a GET request and parses JSON response
    #   @param url [String] The URL to request
    #   @yield [Hash] The parsed JSON response
    #   @return [Response, Object] Response object or yielded value
    #   @see JSONClient#get_json
    #
    # @!method post_json(url, params = {})
    #   Performs a POST request with JSON body
    #   @param url [String] The URL to request
    #   @param params [Hash] Data to send as JSON
    #   @return [Response] Response object
    #   @see JSONClient#post_json
    #
    # @!method put_json(url, params = {})
    #   Performs a PUT request with JSON body
    #   @param url [String] The URL to request
    #   @param params [Hash] Data to send as JSON
    #   @return [Response] Response object
    #   @see JSONClient#put_json
    #
    # @!method patch_json(url, params = {})
    #   Performs a PATCH request with JSON body
    #   @param url [String] The URL to request
    #   @param params [Hash] Data to send as JSON
    #   @return [Response] Response object
    #   @see JSONClient#patch_json
    #
    # @!method delete_json(url, params = {})
    #   Performs a DELETE request
    #   @param url [String] The URL to request
    #   @param params [Hash] Optional data to send as JSON
    #   @return [Response] Response object
    #   @see JSONClient#delete_json
    #
    # @!method get_raw(url)
    #   Performs a GET request and returns raw response
    #   @param url [String] The URL to request
    #   @return [RestClient::Response] Raw response object
    #   @see JSONClient#get_raw
    #
    # @!method get_raw!(url)
    #   Performs a GET request and returns raw response, raising on errors
    #   @param url [String] The URL to request
    #   @return [RestClient::Response] Raw response object
    #   @raise [HTTPClientError, HTTPServerError] On HTTP errors
    #   @see JSONClient#get_raw!
    #
    # @!method put_multipart(url, params = {})
    #   Performs a PUT request with multipart/form-data
    #   @param url [String] The URL to request
    #   @param params [Hash] Multipart form data
    #   @return [Response] Response object
    #   @see JSONClient#put_multipart
    #
    # @!method post_multipart(url, params = {})
    #   Performs a POST request with multipart/form-data
    #   @param url [String] The URL to request
    #   @param params [Hash] Multipart form data
    #   @return [Response] Response object
    #   @see JSONClient#post_multipart
    def_delegators :client,
                   :get_json,
                   :post_json,
                   :put_json,
                   :patch_json,
                   :delete_json,
                   :get_raw,
                   :get_raw!,
                   :put_multipart,
                   :post_multipart

    # @return [Hash] The client configuration options
    attr_reader :options

    class << self
      # @!attribute [w] logger
      #   Sets the default logger for all Base instances
      #   @param value [Logger] Logger instance
      attr_writer :logger

      # @!attribute [rw] default_options
      #   Default options merged into all Base instances
      #   @return [Hash, nil] Default options hash
      attr_accessor :default_options
    end

    # Returns the default logger for Base instances
    #
    # @return [Logger] Logger instance (defaults to NullLogger)
    def self.logger
      @logger ||= ApiAdaptor::NullLogger.new
    end

    # Initializes a new API client
    #
    # @param endpoint_url [String, nil] Base URL for the API
    # @param options [Hash] Configuration options (see JSONClient#initialize for details)
    #
    # @raise [InvalidAPIURL] If endpoint_url is invalid
    #
    # @example Basic initialization
    #   client = Base.new("https://api.example.com")
    #
    # @example With authentication
    #   client = Base.new("https://api.example.com", bearer_token: "abc123")
    def initialize(endpoint_url = nil, options = {})
      options[:endpoint_url] = endpoint_url
      raise InvalidAPIURL if !endpoint_url.nil? && endpoint_url !~ URI::RFC3986_Parser::RFC3986_URI

      base_options = { logger: ApiAdaptor::Base.logger }
      default_options = base_options.merge(ApiAdaptor::Base.default_options || {})
      @options = default_options.merge(options)
      self.endpoint = options[:endpoint_url]
    end

    # Constructs a URL for a given slug with query parameters
    #
    # @param slug [String] The API endpoint slug
    # @param options [Hash] Query parameters to append
    #
    # @return [String] Full URL with .json extension and query string
    #
    # @example
    #   url_for_slug("users/123", include: "posts")
    #   # => "https://api.example.com/users/123.json?include=posts"
    def url_for_slug(slug, options = {})
      "#{base_url}/#{slug}.json#{query_string(options)}"
    end

    # Performs a GET request and wraps the response in a ListResponse
    #
    # @param url [String] The URL to request
    #
    # @return [ListResponse] Paginated response wrapper
    #
    # @example
    #   list = client.get_list("/posts?page=1")
    #   list.results       # => Array of items
    #   list.current_page  # => 1
    #   list.total_pages   # => 10
    def get_list(url)
      get_json(url) do |r|
        ApiAdaptor::ListResponse.new(r, self)
      end
    end

    private

    attr_accessor :endpoint

    def query_string(params)
      return "" if params.empty?

      param_pairs = params.sort.map do |key, value|
        case value
        when Array
          value.map do |v|
            "#{CGI.escape("#{key}[]")}=#{CGI.escape(v.to_s)}"
          end
        else
          "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
        end
      end.flatten

      "?#{param_pairs.join("&")}"
    end

    def uri_encode(param)
      Addressable::URI.encode(param.to_s)
    end
  end
end
