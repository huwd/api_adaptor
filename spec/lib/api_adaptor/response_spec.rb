require "api_adaptor/response"

RSpec.describe ApiAdaptor::Response do
  describe "accessing HTTP response details" do
    before :each do
      @mock_http_response = double(body: "A Response body", code: 200, headers: { cache_control: "public" })
      @response = ApiAdaptor::Response.new(@mock_http_response)
    end

    it "should return the raw response body" do
      expect(@response.raw_response_body).to eq("A Response body")
    end

    it "should return the status code" do
      expect(@response.code).to eq(200)
    end

    it "should pass-on the response headers" do
      expect(@response.headers).to eq({ cache_control: "public" })
    end
  end

  describe ".expires_at" do
    it "should be calculated from cache-control max-age" do
      Timecop.freeze(Time.parse("15:00")) do
        cache_control_headers = { cache_control: "public, max-age=900" }
        headers = cache_control_headers.merge(date: Time.now.httpdate)

        mock_http_response = double(body: "A Response body", code: 200, headers: headers)
        response = ApiAdaptor::Response.new(mock_http_response)

        expect(response.expires_at).to eq(Time.parse("15:15"))
      end
    end

    it "should be same as the value of Expires header in absence of max-age" do
      Timecop.freeze(Time.parse("15:00")) do
        cache_headers = { cache_control: "public", expires: (Time.now + 900).httpdate }
        headers = cache_headers.merge(date: Time.now.httpdate)

        mock_http_response = double(body: "A Response body", code: 200, headers: headers)
        response = ApiAdaptor::Response.new(mock_http_response)

        expect(response.expires_at).to eq(Time.parse("15:15"))
      end
    end

    it "should be nil in absence of Expires header and max-age" do
      mock_http_response = double(body: "A Response body", code: 200, headers: { date: Time.now.httpdate })
      response = ApiAdaptor::Response.new(mock_http_response)

      expect(response.expires_at).to be_nil
    end

    it "should be nil in absence of Date header and max-age" do
      mock_http_response = double(body: "A Response body", code: 200, headers: {})
      response = ApiAdaptor::Response.new(mock_http_response)

      expect(response.expires_at).to be_nil
    end
  end

  describe ".expires_in" do
    it "should be seconds remaining from expiration time inferred from max-age" do
      cache_control_headers = { cache_control: "public, max-age=900" }
      headers = cache_control_headers.merge(date: Time.now.httpdate)
      mock_http_response = double(body: "A Response body", code: 200, headers: headers)

      Timecop.travel(12 * 60) do
        response = ApiAdaptor::Response.new(mock_http_response)
        expect(response.expires_in).to eq(180)
      end
    end

    it "should be seconds remaining from expiration time inferred from Expires header" do
      cache_headers = { cache_control: "public", expires: (Time.now + 900).httpdate }
      headers = cache_headers.merge(date: Time.now.httpdate)
      mock_http_response = double(body: "A Response body", code: 200, headers: headers)

      Timecop.travel(12 * 60) do
        response = ApiAdaptor::Response.new(mock_http_response)
        expect(response.expires_in).to eq(180)
      end
    end

    it "should be nil in absence of Expires header and max-age" do
      mock_http_response = double(body: "A Response body", code: 200, headers: { date: Time.now.httpdate })
      response = ApiAdaptor::Response.new(mock_http_response)

      expect(response.expires_at).to be_nil
    end

    it "should be nil in absence of Date header" do
      cache_control_headers = { cache_control: "public, max-age=900" }
      mock_http_response = double(body: "A Response body", code: 200, headers: cache_control_headers)
      response = ApiAdaptor::Response.new(mock_http_response)

      expect(response.expires_at).to be_nil
    end
  end

  describe "processing web_urls" do
    def build_response(body_string, relative_to = "https://www.web.site")
      ApiAdaptor::Response.new(double(body: body_string), web_urls_relative_to: relative_to)
    end

    it "should map web URLs" do
      body = {
        "web_url" => "https://www.web.site/test"
      }.to_json
      expect(build_response(body)["web_url"]).to eq("/test")
    end

    it "should leave other properties alone" do
      body = {
        "title" => "Title",
        "description" => "Description"
      }.to_json
      response = build_response(body)
      expect(response["title"]).to eq("Title")
      expect(response["description"]).to eq("Description")
    end

    it "should traverse into hashes" do
      body = {
        "details" => {
          "chirality" => "widdershins",
          "web_url" => "https://www.web.site/left"
        }
      }.to_json

      response = build_response(body)
      expect(response["details"]["web_url"]).to eq("/left")
    end

    it "should traverse into arrays" do
      body = {
        "other_urls" => [
          { "title" => "Pies", "web_url" => "https://www.web.site/pies" },
          { "title" => "Cheese", "web_url" => "https://www.web.site/cheese" }
        ]
      }.to_json

      response = build_response(body)
      expect(response["other_urls"][0]["web_url"]).to eq("/pies")
      expect(response["other_urls"][1]["web_url"]).to eq("/cheese")
    end

    it "should handle nil values" do
      body = { "web_url" => nil }.to_json

      response = build_response(body)
      expect(response["web_url"]).to be_nil
    end

    it "should handle query parameters" do
      body = {
        "web_url" => "https://www.web.site/thing?does=stuff"
      }.to_json

      response = build_response(body)
      expect(response["web_url"]).to eq("/thing?does=stuff")
    end

    it "should handle fragments" do
      body = {
        "web_url" => "https://www.web.site/thing#part-2"
      }.to_json

      response = build_response(body)
      expect(response["web_url"]).to eq("/thing#part-2")
    end

    it "should keep URLs from other domains absolute" do
      body = {
        "web_url" => "https://www.example.com/example"
      }.to_json

      response = build_response(body)
      expect(response["web_url"]).to eq("https://www.example.com/example")
    end

    it "should keep URLs with other schemes absolute" do
      body = {
        "web_url" => "http://www.example.com/example"
      }.to_json

      response = build_response(body)
      expect(response["web_url"]).to eq("http://www.example.com/example")
    end
  end

  describe "hash and openstruct access" do
    before :each do
      @response_data = {
        "_response_info" => {
          "status" => "ok"
        },
        "id" => "https://www.web.site/api/vat-rates.json",
        "web_url" => "https://www.web.site/vat-rates",
        "title" => "VAT rates",
        "format" => "answer",
        "updated_at" => "2013-04-04T15:51:54+01:00",
        "details" => {
          "need_id" => "1870",
          "business_proposition" => false,
          "description" => "Current VAT rates - standard 20% and rates for reduced rate and zero-rated items",
          "language" => "en"
        },
        "tags" => [
          { "slug" => "foo" },
          { "slug" => "bar" },
          { "slug" => "baz" }
        ]
      }
      @response = ApiAdaptor::Response.new(double(body: @response_data.to_json))
    end

    describe "behaving like a read-only hash" do
      before do
        @response["id"]
        allow(JSON).to receive(:parse).and_call_original
      end

      it "should allow accessing members by key" do
        expect(@response["title"]).to eq("VAT rates")
      end

      it "should allow accessing nested keys" do
        expect(@response["details"]["need_id"]).to eq("1870")
      end

      it "should return nil for a non-existent key" do
        expect(@response["foo"]).to be_nil
      end

      it "should memoize the parsed hash" do
        expect(JSON).not_to receive(:parse)
        expect(@response["title"]).to eq("VAT rates")
      end

      it "should allow using dig to access nested keys" do
        skip unless RUBY_VERSION > "2.3"
        expect(@response.dig("details", "need_id")).to eq("1870")
      end
    end
  end
end
