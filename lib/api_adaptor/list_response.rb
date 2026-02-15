# frozen_string_literal: true

require "json"
require "api_adaptor/response"
require "link_header"

module ApiAdaptor
  # Response wrapper for paginated API results.
  #
  # ListResponse handles paginated responses using Link headers (RFC 5988) for navigation.
  # It expects responses to have a "results" array and provides methods to navigate through pages.
  #
  # @example Basic usage
  #   response = client.get_list("/posts?page=1")
  #   response.results       # => Array of items on current page
  #   response.next_page?    # => true
  #   response.next_page     # => ListResponse for page 2
  #
  # @example Iterating over current page
  #   response.each do |item|
  #     puts item["title"]
  #   end
  #
  # @example Fetching all pages
  #   response.with_subsequent_pages.each do |item|
  #     puts item["title"]  # Automatically fetches additional pages
  #   end
  class ListResponse < Response
    # Initializes a new ListResponse with API client reference for pagination
    #
    # @param response [RestClient::Response] The raw HTTP response
    # @param api_client [Base] API client instance for fetching additional pages
    # @param options [Hash] Configuration options (see Response#initialize)
    def initialize(response, api_client, options = {})
      super(response, options)
      @api_client = api_client
    end

    # @!method each(&block)
    #   Iterate over results on the current page only
    #   @yield [Hash] Each result item
    #   @see #with_subsequent_pages for iterating across all pages
    #
    # @!method to_ary
    #   Convert results to array
    #   @return [Array] Array of result items on current page
    def_delegators :results, :each, :to_ary

    # Returns the array of results from the current page
    #
    # @return [Array<Hash>] Array of result items
    def results
      to_hash["results"]
    end

    # Checks if there is a next page available
    #
    # @return [Boolean] true if next page exists
    def next_page?
      !page_link("next").nil?
    end

    # Fetches the next page of results
    #
    # Results are memoized to avoid refetching the same page multiple times.
    #
    # @return [ListResponse, nil] Next page response or nil if no next page
    def next_page
      # This shouldn't be a performance problem, since the cache will generally
      # avoid us making multiple requests for the same page, but we shouldn't
      # allow the data to change once it's already been loaded, so long as we
      # retain a reference to any one page in the sequence
      @next_page ||= (@api_client.get_list page_link("next").href if next_page?)
    end

    # Checks if there is a previous page available
    #
    # @return [Boolean] true if previous page exists
    def previous_page?
      !page_link("previous").nil?
    end

    # Fetches the previous page of results
    #
    # Results are memoized to avoid refetching the same page multiple times.
    #
    # @return [ListResponse, nil] Previous page response or nil if no previous page
    def previous_page
      # See the note in `next_page` for why this is memoised
      @previous_page ||= (@api_client.get_list(page_link("previous").href) if previous_page?)
    end

    # Returns an enumerator that transparently fetches and iterates over all pages
    #
    # Pages are fetched on demand as you iterate. If you call a method like #count,
    # all pages will be fetched immediately. Results are memoized to avoid duplicate requests.
    #
    # @return [Enumerator] Enumerator for all results across all pages
    #
    # @example Iterate over all pages
    #   response.with_subsequent_pages.each do |item|
    #     puts item["title"]
    #   end
    #
    # @example Count all items across all pages
    #   total_count = response.with_subsequent_pages.count
    #
    # @example Convert all pages to array
    #   all_items = response.with_subsequent_pages.to_a
    def with_subsequent_pages
      Enumerator.new do |yielder|
        each { |i| yielder << i }
        next_page.with_subsequent_pages.each { |i| yielder << i } if next_page?
      end
    end

    private

    def link_header
      @link_header ||= LinkHeader.parse @http_response.headers[:link]
    end

    def page_link(rel)
      link_header.find_link(["rel", rel])
    end
  end
end
