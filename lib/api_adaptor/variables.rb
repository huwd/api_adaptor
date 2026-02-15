# frozen_string_literal: true

module ApiAdaptor
  # Environment variable configuration for User-Agent metadata
  #
  # These variables are used to construct the User-Agent header for HTTP requests,
  # allowing API providers to identify and contact clients if needed.
  #
  # @example Setting environment variables
  #   ENV["APP_NAME"] = "MyApiClient"
  #   ENV["APP_VERSION"] = "2.1.0"
  #   ENV["APP_CONTACT"] = "dev@example.com"
  #
  # @example User-Agent header format
  #   # "MyApiClient/2.1.0 (dev@example.com)"
  #
  # @see JSONClient.default_request_headers
  module Variables
    # Returns the application name from environment variable
    #
    # @return [String] Application name (default: "Ruby ApiAdaptor App")
    #
    # @example
    #   ENV["APP_NAME"] = "WikidataClient"
    #   Variables.app_name  # => "WikidataClient"
    def self.app_name
      ENV["APP_NAME"] || "Ruby ApiAdaptor App"
    end

    # Returns the application version from environment variable
    #
    # @return [String] Application version (default: "Version not stated")
    #
    # @example
    #   ENV["APP_VERSION"] = "3.2.1"
    #   Variables.app_version  # => "3.2.1"
    def self.app_version
      ENV["APP_VERSION"] || "Version not stated"
    end

    # Returns the application contact from environment variable
    #
    # Should be an email address or URL where API providers can reach you.
    #
    # @return [String] Contact information (default: "Contact not stated")
    #
    # @example
    #   ENV["APP_CONTACT"] = "api@example.com"
    #   Variables.app_contact  # => "api@example.com"
    def self.app_contact
      ENV["APP_CONTACT"] || "Contact not stated"
    end
  end
end
