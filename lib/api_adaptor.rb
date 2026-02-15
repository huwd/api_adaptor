# frozen_string_literal: true

require_relative "api_adaptor/version"
require_relative "api_adaptor/base"

# ApiAdaptor provides a framework for building JSON API clients with minimal boilerplate.
#
# It handles common patterns like request/response parsing, authentication, redirect handling,
# pagination, and error management, allowing you to focus on your API's specific logic.
#
# @example Building a simple API client
#   class MyApiClient < ApiAdaptor::Base
#     def initialize
#       super("https://api.example.com")
#     end
#
#     def get_user(id)
#       get_json("/users/#{id}")
#     end
#
#     def create_user(data)
#       post_json("/users", data)
#     end
#   end
#
#   client = MyApiClient.new
#   user = client.get_user(123)
#
# @example Using JSONClient directly
#   client = ApiAdaptor::JSONClient.new(bearer_token: "abc123")
#   response = client.get_json("https://api.example.com/data")
#   puts response["items"]
#
# @see Base Base class for building API clients
# @see JSONClient Low-level HTTP client with JSON support
module ApiAdaptor
  # Base error class for all ApiAdaptor exceptions
  class Error < StandardError; end
end
