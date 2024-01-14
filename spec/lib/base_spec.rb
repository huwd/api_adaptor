# frozen_string_literal: true

require "api_adaptor/base"
require "uri"

RSpec.describe ApiAdaptor::Base do
  class ConcreteApi < described_class
    def base_url
      endpoint
    end
  end

  after do
    described_class.default_options = nil
  end

  it "should construct escaped query string" do
    api = ConcreteApi.new("http://foo")
    url = api.url_for_slug("slug", "a" => " ", "b" => "/")
    u = URI.parse(url)
    expect(u.query).to eq "a=+&b=%2F"
  end

  it "should construct escaped query string for rails" do
    api = ConcreteApi.new("http://foo")

    url = api.url_for_slug("slug", "b" => %w[123])
    u = URI.parse(url)
    expect(u.query).to eq "b%5B%5D=123"

    url = api.url_for_slug("slug", "b" => %w[123 456])
    u = URI.parse(url)
    expect(u.query).to eq "b%5B%5D=123&b%5B%5D=456"
  end

  it "should not add a question mark if there are no parameters" do
    api = ConcreteApi.new("http://foo")
    url = api.url_for_slug("slug")
    expect(url).not_to match(/\?/)
  end

  it "should use endpoint in url" do
    api = ConcreteApi.new("http://foobarbaz")
    url = api.url_for_slug("slug")
    u = URI.parse(url)
    expect(u.host).to match(/foobarbaz$/)
  end

  it "should accept options as second arg" do
    api = ConcreteApi.new("http://foo", foo: "bar")
    expect(api.options[:foo]).to eq "bar"
  end

  it "should barf if not given valid url" do
    expect { ConcreteApi.new("invalid-url") }.to raise_error(ApiAdaptor::Base::InvalidAPIURL)
  end

  it "should set json client logger to own logger by default" do
    api = ConcreteApi.new("http://bar")
    expect(api.client.logger).to eq described_class.logger
  end

  it "should set json client logger to logger in default options" do
    custom_logger = double("custom-logger")
    described_class.default_options = { logger: custom_logger }
    api = ConcreteApi.new("http://bar")
    expect(api.client.logger).to eq custom_logger
  end

  it "should set json client logger to logger in options" do
    custom_logger = double("custom-logger")
    described_class.default_options = { logger: custom_logger }
    another_logger = double("another-logger")
    api = ConcreteApi.new("http://bar", logger: another_logger)
    expect(api.client.logger).to eq another_logger
  end
end
