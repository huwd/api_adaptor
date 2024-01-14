# frozen_string_literal: true

require "api_adaptor/headers"

RSpec.describe ApiAdaptor::Headers do
  before :each do
    Thread.current[:headers] = nil if Thread.current[:headers]
  end

  after :each do
    ApiAdaptor::Headers.clear_headers
  end

  it "supports read/write of headers" do
    ApiAdaptor::Headers.set_header("Accept-Language", "en-US,en;q=0.5")
    ApiAdaptor::Headers.set_header("Content-Type", "application/pdf")

    expect(ApiAdaptor::Headers.headers).to eq(
      {
        "Accept-Language" => "en-US,en;q=0.5",
        "Content-Type" => "application/pdf"
      }
    )
  end

  it "supports clearing of headers" do
    ApiAdaptor::Headers.set_header("Accept-Language", "en-US,en;q=0.5")
    ApiAdaptor::Headers.clear_headers

    expect(ApiAdaptor::Headers.headers).to eq({})
  end
end
