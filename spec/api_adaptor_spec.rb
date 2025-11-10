# frozen_string_literal: true

require "json"

RSpec.describe ApiAdaptor::Base do
  describe "Acceptance tests" do
    let(:client) { ApiAdaptor::Base.new }
    let(:github_pages_url) { "https://huwd.github.io/api_adaptor" }
    let(:client_with_base) { ApiAdaptor::Base.new(github_pages_url) }
    let(:fixture_path) { File.expand_path("../fixtures/v1/integration/foo.json", __dir__) }
    let(:file_data) { File.read(fixture_path) }

    describe "initalization" do
      it "can be initalized with no parameters" do
        expect { ApiAdaptor::Base.new }.not_to raise_error
      end

      describe "with endpoint_url parameter" do
        it "can be initalized without an error" do
          expect { ApiAdaptor::Base.new("http://example.com") }.not_to raise_error
        end

        it "raises error if given invalid URL" do
          expect { ApiAdaptor::Base.new("invalid-url") }.to raise_error(ApiAdaptor::Base::InvalidAPIURL)
        end

        it "exposes the endpoint URL via options" do
          expect(ApiAdaptor::Base.new("http://example.com").options[:endpoint_url]).to eq("http://example.com")
        end
      end
    end

    describe "get_json" do
      it "can request valid JSON from a client" do
        stub_request(:get, "https://huwd.github.io/api_adaptor/foo.json")
          .with(
            headers: {
              "Accept" => "application/json",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Host" => "huwd.github.io",
              "User-Agent" => "Ruby ApiAdaptor App/Version not stated (Contact not stated)"
            }
          )
          .to_return(status: 200, body: file_data, headers: {})
        json = client.get_json("#{github_pages_url}/foo.json")
        expect(json.parsed_content).to eq(JSON.parse(file_data))
      end
    end

    describe "get_raw" do
      it "can request raw JSON from a client" do
        stub_request(:get, "https://huwd.github.io/api_adaptor/foo.json")
          .with(
            headers: {
              "Accept" => "application/json",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Host" => "huwd.github.io",
              "User-Agent" => "Ruby ApiAdaptor App/Version not stated (Contact not stated)"
            }
          )
          .to_return(status: 200, body: file_data, headers: {})
        response = client.get_raw("#{github_pages_url}/foo.json")
        expect(response.body).to eq(file_data)
      end
    end
  end
end
