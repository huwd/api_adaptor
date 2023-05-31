require_relative "json_client"
require "cgi"
require_relative "null_logger"
require_relative "list_response"

class ApiAdaptor::Base
  class InvalidAPIURL < StandardError
  end

  extend Forwardable

  def client
    @client ||= create_client
  end

  def create_client
    ApiAdaptor::JsonClient.new(options)
  end

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

  attr_reader :options

  class << self
    attr_writer :logger
    attr_accessor :default_options
  end

  def self.logger
    @logger ||= ApiAdaptor::NullLogger.new
  end

  def initialize(endpoint_url, options = {})
    options[:endpoint_url] = endpoint_url
    raise InvalidAPIURL unless endpoint_url =~ URI::RFC3986_Parser::RFC3986_URI

    base_options = { logger: ApiAdaptor::Base.logger }
    default_options = base_options.merge(ApiAdaptor::Base.default_options || {})
    @options = default_options.merge(options)
    self.endpoint = options[:endpoint_url]
  end

  def url_for_slug(slug, options = {})
    "#{base_url}/#{slug}.json#{query_string(options)}"
  end

  def get_list(url)
    get_json(url) do |r|
      ApiAdaptor::ListResponse.new(r, self)
    end
  end

private

  attr_accessor :endpoint

  def query_string(params)
    return "" if params.empty?

    param_pairs = params.sort.map { |key, value|
      case value
      when Array
        value.map do |v|
          "#{CGI.escape("#{key}[]")}=#{CGI.escape(v.to_s)}"
        end
      else
        "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
      end
    }.flatten

    "?#{param_pairs.join('&')}"
  end

  def uri_encode(param)
    Addressable::URI.encode(param.to_s)
  end
end