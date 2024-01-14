# frozen_string_literal: true

require "api_adaptor/json_client"

RSpec.describe ApiAdaptor::JsonClient do
  let(:client) { ApiAdaptor::JsonClient.new }

  describe "client" do
    it "can use basic auth" do
      client = ApiAdaptor::JsonClient.new(basic_auth: { user: "user", password: "password" })
      stub_request(:put, "http://some.endpoint/some.json").with(basic_auth: %w[user password]).to_return(
        body: "{\"a\":1}", status: 200
      )
      response = client.put_json("http://some.endpoint/some.json", {})
      expect(response["a"]).to(eq(1))
    end

    it "can use bearer token" do
      client = ApiAdaptor::JsonClient.new(bearer_token: "SOME_BEARER_TOKEN")
      expected_headers = ApiAdaptor::JsonClient.default_request_with_json_body_headers.merge("Authorization" => "Bearer SOME_BEARER_TOKEN")
      stub_request(:put, "http://some.other.endpoint/some.json").with(headers: expected_headers).to_return(
        body: "{\"a\":2}", status: 200
      )
      response = client.put_json("http://some.other.endpoint/some.json", {})
      expect(response["a"]).to(eq(2))
    end

    it "should raise error if attempting to disable timeout" do
      expect { ApiAdaptor::JsonClient.new(disable_timeout: true) }.to(raise_error(RuntimeError))
      expect { ApiAdaptor::JsonClient.new(timeout: -1) }.to(raise_error(RuntimeError))
    end

    it "should default to using null logger" do
      expect(client.logger).to be_an_instance_of(ApiAdaptor::NullLogger)
    end

    it "should use custom logger specified in options" do
      custom_logger = double("custom-logger")
      client = ApiAdaptor::JsonClient.new(logger: custom_logger)
      expect(client.logger).to eq(custom_logger)
    end

    it "govuk headers are included in requests if present" do
      ApiAdaptor::Headers.set_header(:govuk_request_id, "12345")
      ApiAdaptor::Headers.set_header(:govuk_original_url, "http://example.com")
      stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)
      ApiAdaptor::JsonClient.new.get_json("http://some.other.endpoint/some.json")
      assert_requested(:get, %r{/some.json}) do |request|
        (request.headers["Govuk-Request-Id"] == "12345") and (request.headers["Govuk-Original-Url"] == "http://example.com")
      end
    end

    it "govuk headers ignored in requests if not present" do
      ApiAdaptor::Headers.set_header(:x_govuk_authenticated_user, "")
      stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)
      ApiAdaptor::JsonClient.new.get_json("http://some.other.endpoint/some.json")
      assert_requested(:get, %r{/some.json}) do |request|
        !request.headers.key?("X-Govuk-Authenticated-User")
      end
    end

    it "additional headers passed in do not get modified" do
      stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)
      headers = { "HEADER-A" => "A" }
      ApiAdaptor::JsonClient.new.get_json("http://some.other.endpoint/some.json", headers)
      expect(headers).to(eq("HEADER-A" => "A"))
    end
  end

  describe "#get_json" do
    describe "client" do
      it "can set custom headers on gets" do
        stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)
        ApiAdaptor::JsonClient.new.get_json("http://some.other.endpoint/some.json", "HEADER-A" => "B",
                                                                                    "HEADER-C" => "D")
        assert_requested(:get, %r{/some.json}) do |request|
          headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
          ((headers_with_uppercase_names["HEADER-A"] == "B") and (headers_with_uppercase_names["HEADER-C"] == "D"))
        end
      end

      it "avoids setting content type headers without a body" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url)
        client.get_json(url)
        assert_requested(:get, url, headers: ApiAdaptor::JsonClient.default_request_headers)
      end
    end

    describe "when things go well" do
      it "should fetch and parse json into response" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_return(body: "{}", status: 200)
        expect(client.get_json(url).class).to(eq(ApiAdaptor::Response))
      end
    end

    describe "custom responses" do
      it "can build a custom response object" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_return(body: "Hello there!")
        response = client.get_json(url, &:body)
        expect(response.is_a?(String)).to(eq(true))
        expect(response).to(eq("Hello there!"))
      end

      it "raises HTTPNotFound on custom response 404" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_return(body: "", status: 404)
        expect { client.get_json(url, &:body) }.to(raise_error(ApiAdaptor::HTTPNotFound))
      end
    end

    describe "when handling exceptions" do
      it "raises TimedOutException for long requests" do
        url = "http://www.example.com/timeout.json"
        stub_request(:get, url).to_timeout
        expect { client.get_json(url) }.to raise_error(ApiAdaptor::TimedOutException)
      end

      it "raises TimedOutException for connection timeouts" do
        url = "http://www.example.com/timeout.json"
        exception = defined?(Net::OpenTimeout) ? Net::OpenTimeout : TimeoutError
        stub_request(:get, url).to_raise(exception)

        expect { client.get_json(url) }.to raise_error(ApiAdaptor::TimedOutException)
      end

      it "raises InvalidUrl for invalid URLs" do
        url = "http://www.example.com/there-is-a-space-in-this-slug /"
        stub_request(:get, url).to_timeout
        expect { client.get_json(url) }.to raise_error(ApiAdaptor::InvalidUrl)
      end

      it "raises EndpointNotFound if connection refused" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_raise(Errno::ECONNREFUSED)
        expect { client.get_json(url) }.to(raise_error(ApiAdaptor::EndpointNotFound))
      end

      it "raises SocketErrorException for socket errors" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_raise(SocketError)
        expect { client.get_json(url) }.to(raise_error(ApiAdaptor::SocketErrorException))
      end

      it "raises HTTPErrorResponse if RestClient raises ServerBrokeConnection" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_raise(RestClient::ServerBrokeConnection)
        expect { client.get_json(url) }.to(raise_error(ApiAdaptor::HTTPErrorResponse))
      end
    end

    describe "when encountering a HTTP error" do
      it "raises HTTPForbidden if the endpoint returns 403" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_return(body: "{}", status: 403)
        expect { client.get_json(url) }.to(raise_error(ApiAdaptor::HTTPForbidden))
      end

      it "raises HTTPNotFound if the endpoint returns 404" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_return(body: "{}", status: 404)
        expect { client.get_json(url) }.to(raise_error(ApiAdaptor::HTTPNotFound))
      end

      it "raises HTTPGone if the endpoint returns 410" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_return(body: "{}", status: 410)
        expect { client.get_json(url) }.to(raise_error(ApiAdaptor::HTTPGone))
      end

      it "raises HTTPServerError if the endpoint returns 500" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_return(body: "{}", status: 500)
        expect { client.get_json(url) }.to(raise_error(ApiAdaptor::HTTPServerError))
      end
    end

    describe "when following redirects" do
      it "follows permanent redirect" do
        url = "http://some.endpoint/some.json"
        new_url = "http://some.endpoint/other.json"
        stub_request(:get, url).to_return(body: "", status: 301, headers: { "Location" => new_url })
        stub_request(:get, new_url).to_return(body: "{\"a\": 1}", status: 200)
        result = client.get_json(url)
        expect(result["a"]).to(eq(1))
      end

      it "follows 302 found redirect" do
        url = "http://some.endpoint/some.json"
        new_url = "http://some.endpoint/other.json"
        stub_request(:get, url).to_return(body: "", status: 302, headers: { "Location" => new_url })
        stub_request(:get, new_url).to_return(body: "{\"a\": 1}", status: 200)
        result = client.get_json(url)
        expect(result["a"]).to(eq(1))
      end

      it "follows 303 see other" do
        url = "http://some.endpoint/some.json"
        new_url = "http://some.endpoint/other.json"
        stub_request(:get, url).to_return(body: "", status: 303, headers: { "Location" => new_url })
        stub_request(:get, new_url).to_return(body: "{\"a\": 1}", status: 200)
        result = client.get_json(url)
        expect(result["a"]).to(eq(1))
      end

      it "follows 307 temporary redirect" do
        url = "http://some.endpoint/some.json"
        new_url = "http://some.endpoint/other.json"
        stub_request(:get, url).to_return(body: "", status: 307, headers: { "Location" => new_url })
        stub_request(:get, new_url).to_return(body: "{\"a\": 1}", status: 200)
        result = client.get_json(url)
        expect(result["a"]).to(eq(1))
      end

      it "should handle infinite 302 redirects" do
        url = "http://some.endpoint/some.json"
        redirect = { body: "", status: 302, headers: { "Location" => url } }
        failure = ->(_request) { flunk("Request called too many times") }
        stub_request(:get, url).to_return(redirect).times(11).then.to_return(failure)
        expect { client.get_json(url) }.to(raise_error(ApiAdaptor::HTTPErrorResponse))
      end

      it "should handle mutual 302 redirects" do
        first_url = "http://some.endpoint/some.json"
        second_url = "http://some.endpoint/some-other.json"
        first_redirect = { body: "", status: 302, headers: { "Location" => second_url } }
        second_redirect = { body: "", status: 302, headers: { "Location" => first_url } }
        failure = ->(_request) { flunk("Request called too many times") }
        stub_request(:get, first_url).to_return(first_redirect).times(6).then.to_return(failure)
        stub_request(:get, second_url).to_return(second_redirect).times(6).then.to_return(failure)
        expect { client.get_json(first_url) }.to(raise_error(ApiAdaptor::HTTPErrorResponse))
      end
    end
  end

  describe "#post_json" do
    describe "client" do
      it "can set custom headers on gets" do
        stub_request(:post, "http://some.other.endpoint/some.json").to_return(status: 200)
        ApiAdaptor::JsonClient.new.post_json("http://some.other.endpoint/some.json", {}, "HEADER-A" => "B",
                                                                                         "HEADER-C" => "D")
        assert_requested(:post, %r{/some.json}) do |request|
          headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
          ((headers_with_uppercase_names["HEADER-A"] == "B") and (headers_with_uppercase_names["HEADER-C"] == "D"))
        end
      end

      it "avoids setting content type headers without a body" do
        url = "http://some.endpoint/some.json"
        stub_request(:post, url)
        client.post_json(url)
        assert_requested(:post, url, headers: ApiAdaptor::JsonClient.default_request_with_json_body_headers)
      end
    end

    describe "When handling exceptions" do
      it "raises EndpointNotFound if connection refused" do
        url = "http://some.endpoint/some.json"
        stub_request(:post, url).to_raise(Errno::ECONNREFUSED)
        expect { client.post_json(url) }.to(raise_error(ApiAdaptor::EndpointNotFound))
      end

      it "raises TimedOutException for long requests" do
        url = "http://some.endpoint/some.json"
        stub_request(:post, url).to_timeout
        expect { client.post_json(url, {}) }.to(raise_error(ApiAdaptor::TimedOutException))
      end
    end

    describe "when encountering a HTTP error" do
      it "raises HTTPForbidden if the endpoint returns 403" do
        url = "http://some.endpoint/some.json"
        stub_request(:post, url).to_return(body: "{}", status: 403)
        expect { client.post_json(url) }.to(raise_error(ApiAdaptor::HTTPForbidden))
      end

      it "raises HTTPNotFound if the endpoint returns 404" do
        url = "http://some.endpoint/some.json"
        stub_request(:post, url).to_return(body: "{}", status: 404)
        expect { client.post_json(url) }.to(raise_error(ApiAdaptor::HTTPNotFound))
      end

      it "raises HTTPGone if the endpoint returns 410" do
        url = "http://some.endpoint/some.json"
        stub_request(:post, url).to_return(body: "{}", status: 410)
        expect { client.post_json(url) }.to(raise_error(ApiAdaptor::HTTPGone))
      end

      it "raises HTTPServerError if the endpoint returns 500" do
        url = "http://some.endpoint/some.json"
        stub_request(:post, url).to_return(body: "{}", status: 500)
        expect { client.post_json(url) }.to(raise_error(ApiAdaptor::HTTPServerError))
      end
    end

    describe "when following redirects" do
      it "raises HTTPErrorResponse on 302 redirect" do
        url = "http://some.endpoint/some.json"
        new_url = "http://some.endpoint/other.json"
        stub_request(:post, url).to_return(body: "{}", status: 302, headers: { "Location" => new_url })
        expect { client.post_json(url, {}) }.to(raise_error(ApiAdaptor::HTTPErrorResponse))
      end
    end
  end

  describe "#put_json" do
    describe "client" do
      it "can set custom headers on puts" do
        stub_request(:put, "http://some.other.endpoint/some.json").to_return(status: 200)
        ApiAdaptor::JsonClient.new.put_json("http://some.other.endpoint/some.json", {}, "HEADER-A" => "B",
                                                                                        "HEADER-C" => "D")
        assert_requested(:put, %r{/some.json}) do |request|
          headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
          ((headers_with_uppercase_names["HEADER-A"] == "B") and (headers_with_uppercase_names["HEADER-C"] == "D"))
        end
      end

      it "avoids setting content type headers without a body" do
        url = "http://some.endpoint/some.json"
        stub_request(:put, url)
        client.put_json(url, {})

        expect(a_request(:put, url)
          .with(headers: ApiAdaptor::JsonClient.default_request_with_json_body_headers)).to have_been_made
      end
    end

    describe "responses" do
      it "are always considered present and not blank" do
        url = "http://some.endpoint/some.json"
        stub_request(:put, url).to_return(body: "{\"a\":1}", status: 200)
        response = client.put_json(url, {})
        expect(!response.blank?).to(be_truthy)
        expect(response.present?).to(eq(true))
      end
    end

    describe "encoding" do
      it "JSON encodes the payload " do
        url = "http://some.endpoint/some.json"
        payload = { a: 1 }
        stub_request(:put, url).with(body: payload.to_json).to_return(body: "{}", status: 200)
        expect(client.put_json(url, payload).to_hash).to(eq({}))
      end

      it "does not encode JSON if payload is nil" do
        url = "http://some.endpoint/some.json"
        stub_request(:put, url).with(body: nil).to_return(body: "{}", status: 200)
        expect(client.put_json(url, nil).to_hash).to(eq({}))
      end
    end

    describe "when encountering a HTTP error" do
      it "raises HTTPForbidden if the endpoint returns 403" do
        url = "http://some.endpoint/some.json"
        stub_request(:put, url).to_return(body: "{}", status: 403)
        expect { client.put_json(url, {}) }.to(raise_error(ApiAdaptor::HTTPForbidden))
      end

      it "raises HTTPNotFound if the endpoint returns 404" do
        url = "http://some.endpoint/some.json"
        stub_request(:put, url).to_return(body: "{}", status: 404)
        expect { client.put_json(url, {}) }.to(raise_error(ApiAdaptor::HTTPNotFound))
      end

      it "raises HTTPGone if the endpoint returns 410" do
        url = "http://some.endpoint/some.json"
        stub_request(:put, url).to_return(body: "{}", status: 410)
        expect { client.put_json(url, {}) }.to(raise_error(ApiAdaptor::HTTPGone))
      end

      it "raises HTTPServerError if the endpoint returns 500" do
        url = "http://some.endpoint/some.json"
        stub_request(:put, url).to_return(body: "{}", status: 500)
        expect { client.put_json(url, {}) }.to(raise_error(ApiAdaptor::HTTPServerError))
      end
    end
  end

  describe "#delete_json" do
    describe "client" do
      it "can set custom headers on deletes" do
        stub_request(:delete, "http://some.other.endpoint/some.json").to_return(status: 200)
        ApiAdaptor::JsonClient.new.delete_json("http://some.other.endpoint/some.json", {}, "HEADER-A" => "B",
                                                                                           "HEADER-C" => "D")
        assert_requested(:delete, %r{/some.json}) do |request|
          headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
          ((headers_with_uppercase_names["HEADER-A"] == "B") and (headers_with_uppercase_names["HEADER-C"] == "D"))
        end
      end

      it "avoids setting content type headers without a body" do
        url = "http://some.endpoint/some.json"
        stub_request(:delete, url)
        client.delete_json(url)
        assert_requested(:delete, url, headers: ApiAdaptor::JsonClient.default_request_headers)
      end
    end

    describe "when encountering a HTTP error" do
      it "raises HTTPConflict if the endpoint returns 409" do
        url = "http://some.endpoint/some.json"
        stub_request(:delete, url).to_return(body: "{}", status: 409)
        expect { client.delete_json(url) }.to(raise_error(ApiAdaptor::HTTPConflict))
      end
    end
  end

  describe "#get_raw" do
    describe "when encountering a HTTP error" do
      it "raises HTTPNotFound if the endpoint returns 404" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_return(body: "{}", status: 404)
        expect { client.get_raw(url) }.to(raise_error(ApiAdaptor::HTTPNotFound))
      end

      it "raises HTTPGone if the endpoint returns 410" do
        url = "http://some.endpoint/some.json"
        stub_request(:get, url).to_return(body: "{}", status: 410)
        expect { client.get_raw(url) }.to(raise_error(ApiAdaptor::HTTPGone))
      end
    end
  end

  describe "#post_multipart" do
    it "can post multipart responses" do
      url = "http://some.endpoint/some.json"
      stub_request(:post, url).with(headers: { "Content-Type" => %r{multipart/form-data; boundary=----RubyFormBoundary\w+} }) do |request|
        request.body =~ /------RubyFormBoundary\w+\r\nContent-Disposition: form-data; name="a"\r\n\r\n123\r\n------RubyFormBoundary\w+--\r\n/
      end.to_return(body: "{\"b\": \"1\"}", status: 200)
      response = client.post_multipart("http://some.endpoint/some.json", "a" => "123")
      expect(response["b"]).to(eq("1"))
    end

    it "does not send content type header for multipart" do
      expect(RestClient::Request).to receive(:execute).with(hash_including(headers: hash_not_including("Content-Type")))
      client.post_multipart("http://example.com", {})
    end

    describe "when encountering a HTTP error" do
      it "raises HTTPNotFound if the endpoint returns 404" do
        url = "http://some.endpoint/some.json"
        stub_request(:post, url).to_return(body: "", status: 404)
        expect do
          client.post_multipart("http://some.endpoint/some.json", "a" => "123")
        end.to(raise_error(ApiAdaptor::HTTPNotFound))
      end

      it "raises HTTPServerError if the endpoint returns 500" do
        url = "http://some.endpoint/some.json"
        stub_request(:post, url).to_return(body: "", status: 500)
        expect do
          client.post_multipart("http://some.endpoint/some.json", "a" => "123")
        end.to(raise_error(ApiAdaptor::HTTPServerError))
      end
    end
  end

  describe "#put_multipart" do
    it "can post multipart responses" do
      url = "http://some.endpoint/some.json"
      stub_request(:put, url).with(headers: { "Content-Type" => %r{multipart/form-data; boundary=----RubyFormBoundary\w+} }) do |request|
        request.body =~ /------RubyFormBoundary\w+\r\nContent-Disposition: form-data; name="a"\r\n\r\n123\r\n------RubyFormBoundary\w+--\r\n/
      end.to_return(body: "{\"b\": \"1\"}", status: 200)
      response = client.put_multipart("http://some.endpoint/some.json", "a" => "123")
      expect(response["b"]).to(eq("1"))
    end

    describe "when encountering a HTTP error" do
      it "raises HTTPNotFound if the endpoint returns 404" do
        url = "http://some.endpoint/some.json"
        stub_request(:put, url).to_return(body: "", status: 404)
        expect do
          client.put_multipart("http://some.endpoint/some.json", "a" => "123")
        end.to(raise_error(ApiAdaptor::HTTPNotFound))
      end

      it "raises HTTPServerError if the endpoint returns 500" do
        url = "http://some.endpoint/some.json"
        stub_request(:put, url).to_return(body: "", status: 500)
        expect do
          client.put_multipart("http://some.endpoint/some.json", "a" => "123")
        end.to(raise_error(ApiAdaptor::HTTPServerError))
      end
    end

    it "does not send content type header for multipart" do
      expect(RestClient::Request).to receive(:execute).with(hash_including(headers: hash_not_including("Content-Type")))
      client.put_multipart("http://example.com", {})
    end
  end
end
