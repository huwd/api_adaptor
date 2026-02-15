# frozen_string_literal: true

require "json"
require "forwardable"

module ApiAdaptor
  # Wraps an HTTP response with a JSON body and provides convenient access methods.
  #
  # Response objects parse JSON and provide hash-like access to the response body.
  # They also handle cache control headers and can convert absolute URLs to relative URLs.
  #
  # @example Basic usage
  #   response = client.get_json("https://api.example.com/users")
  #   users = response["results"]
  #   cache_duration = response.cache_control.max_age
  #
  # @example With relative URLs
  #   response = Response.new(http_response, web_urls_relative_to: "https://www.example.com")
  #   response['results'][0]['web_url']  # => "/foo" instead of "https://www.example.com/foo"
  #
  # @example Checking cache headers
  #   if response.cache_control.public? && response.cache_control.max_age > 300
  #     # Cache this response
  #   end
  class Response
    extend Forwardable
    include Enumerable

    # Parses and provides access to HTTP Cache-Control header directives.
    #
    # @example
    #   cc = CacheControl.new("public, max-age=3600, must-revalidate")
    #   cc.public?          # => true
    #   cc.max_age          # => 3600
    #   cc.must_revalidate? # => true
    class CacheControl < Hash
      # Regex pattern for parsing Cache-Control directives
      PATTERN = /([-a-z]+)(?:\s*=\s*([^,\s]+))?,?+/i

      # Initializes a new CacheControl object by parsing a header value
      #
      # @param value [String, nil] Cache-Control header value
      def initialize(value = nil)
        super()
        parse(value)
      end

      # @return [Boolean] true if cache is public
      def public?
        self["public"]
      end

      # @return [Boolean] true if cache is private
      def private?
        self["private"]
      end

      # @return [Boolean] true if no-cache directive is present
      def no_cache?
        self["no-cache"]
      end

      # @return [Boolean] true if no-store directive is present
      def no_store?
        self["no-store"]
      end

      # @return [Boolean] true if must-revalidate directive is present
      def must_revalidate?
        self["must-revalidate"]
      end

      # @return [Boolean] true if proxy-revalidate directive is present
      def proxy_revalidate?
        self["proxy-revalidate"]
      end

      # Returns the max-age directive value
      #
      # @return [Integer, nil] Maximum age in seconds, or nil if not present
      def max_age
        self["max-age"].to_i if key?("max-age")
      end

      # Returns the r-maxage (reverse max age) directive value
      #
      # @return [Integer, nil] Reverse maximum age in seconds, or nil if not present
      def reverse_max_age
        self["r-maxage"].to_i if key?("r-maxage")
      end
      alias r_maxage reverse_max_age

      # Returns the s-maxage (shared max age) directive value
      #
      # @return [Integer, nil] Shared maximum age in seconds, or nil if not present
      def shared_max_age
        self["s-maxage"].to_i if key?("r-maxage")
      end
      alias s_maxage shared_max_age

      def to_s
        directives = []
        values = []

        each do |key, value|
          if value == true
            directives << key
          elsif value
            values << "#{key}=#{value}"
          end
        end

        (directives.sort + values.sort).join(", ")
      end

      private

      def parse(header)
        return if header.nil? || header.empty?

        header.scan(PATTERN).each do |name, value|
          self[name.downcase] = value || true
        end
      end
    end

    # @!method [](key)
    #   Access parsed JSON response by key
    #   @param key [String, Symbol] The key to access
    #   @return [Object] The value at the key
    #
    # @!method <=>(other)
    #   Compare responses
    #   @param other [Response] Another response
    #   @return [Integer] Comparison result
    #
    # @!method each(&block)
    #   Iterate over parsed response hash
    #   @yield [key, value] Each key-value pair
    #
    # @!method dig(*keys)
    #   Dig into nested hash structure
    #   @param keys [Array] Keys to traverse
    #   @return [Object, nil] The value at the path or nil
    def_delegators :to_hash, :[], :"<=>", :each, :dig

    # Initializes a new Response object
    #
    # @param http_response [RestClient::Response] The raw HTTP response
    # @param options [Hash] Configuration options
    # @option options [String] :web_urls_relative_to Base URL for converting absolute URLs to relative
    #
    # @example
    #   response = Response.new(http_response)
    #
    # @example With relative URLs
    #   response = Response.new(http_response, web_urls_relative_to: "https://www.example.com")
    def initialize(http_response, options = {})
      @http_response = http_response
      @web_urls_relative_to = options[:web_urls_relative_to] ? URI.parse(options[:web_urls_relative_to]) : nil
    end

    # Returns the raw response body string
    #
    # @return [String] Raw response body
    def raw_response_body
      @http_response.body
    end

    # Returns the HTTP status code
    #
    # @return [Integer] HTTP status code
    def code
      # Return an integer code for consistency with HTTPErrorResponse
      @http_response.code
    end

    # Returns the response headers
    #
    # @return [Hash] HTTP headers
    def headers
      @http_response.headers
    end

    # Calculates when the response expires based on cache headers
    #
    # @return [Time, nil] Expiration time or nil if not cacheable
    def expires_at
      if headers[:date] && cache_control.max_age
        response_date = Time.parse(headers[:date])
        response_date + cache_control.max_age
      elsif headers[:expires]
        Time.parse(headers[:expires])
      end
    end

    # Calculates how many seconds until the response expires
    #
    # @return [Integer, nil] Seconds until expiration or nil if not cacheable
    def expires_in
      return unless headers[:date]

      age = Time.now.utc - Time.parse(headers[:date])

      if cache_control.max_age
        cache_control.max_age - age.to_i
      elsif headers[:expires]
        Time.parse(headers[:expires]).to_i - Time.now.utc.to_i
      end
    end

    # Returns parsed Cache-Control header
    #
    # @return [CacheControl] Parsed cache control directives
    def cache_control
      @cache_control ||= CacheControl.new(headers[:cache_control])
    end

    # Returns the parsed JSON response as a hash
    #
    # @return [Hash] Parsed JSON response
    def to_hash
      parsed_content
    end

    # Returns the parsed and transformed JSON content
    #
    # @return [Hash, Array] Parsed JSON with transformed web_urls
    def parsed_content
      @parsed_content ||= transform_parsed(JSON.parse(@http_response.body))
    end

    # Always returns true (response is present)
    #
    # @return [Boolean] true
    def present?
      true
    end

    # Always returns false (response is not blank)
    #
    # @return [Boolean] false
    def blank?
      false
    end

    private

    def transform_parsed(value)
      return value if @web_urls_relative_to.nil?

      case value
      when Hash
        Hash[value.map do |k, v|
          # NOTE: Don't bother transforming if the value is nil
          if k == "web_url" && v
            # Use relative URLs to route when the web_url value is on the
            # same domain as the site root. Note that we can't just use the
            # `route_to` method, as this would give us technically correct
            # but potentially confusing `//host/path` URLs for URLs with the
            # same scheme but different hosts.
            relative_url = @web_urls_relative_to.route_to(v)
            [k, relative_url.host ? v : relative_url.to_s]
          else
            [k, transform_parsed(v)]
          end
        end]
      when Array
        value.map { |v| transform_parsed(v) }
      else
        value
      end
    end
  end
end
