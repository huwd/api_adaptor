require "api_adaptor/list_response"

RSpec.describe ApiAdaptor::ListResponse do
  describe "accessing results" do
    it "should allow Enumerable access to the results array" do
      data = {
        "results" => %w[foo bar baz],
        "total" => 3,
        "_response_info" => {
          "status" => "ok",
        },
      }
      response = ApiAdaptor::ListResponse.new(double(body: data.to_json), nil)

      expect(response.first).to eq "foo"
      expect(response.to_a).to eq %w[foo bar baz]
      expect(response.any?).to be_truthy
    end

    it "should handle an empty result set" do
      data = {
        "results" => [],
        "total" => 0,
        "_response_info" => {
          "status" => "ok",
        },
      }
      response = ApiAdaptor::ListResponse.new(double(body: data.to_json), nil)

      expect(response.to_a).to eq []
      expect(response.none?).to be_truthy
    end
  end

  describe "handling pagination" do
    before :each do
      page1 = {
        "results" => %w[foo1 bar1],
        "total" => 6,
        "current_page" => 1,
        "pages" => 3,
        "page_size" => 2,
        "_response_info" => {
          "status" => "ok",
          "links" => [
            { "href" => "http://www.example.com/2", "rel" => "next" },
            { "href" => "http://www.example.com/1", "rel" => "self" },
          ],
        },
      }
      page2 = {
        "results" => %w[foo2 bar2],
        "total" => 6,
        "current_page" => 2,
        "pages" => 3,
        "page_size" => 2,
        "_response_info" => {
          "status" => "ok",
          "links" => [
            { "href" => "http://www.example.com/1", "rel" => "previous" },
            { "href" => "http://www.example.com/3", "rel" => "next" },
            { "href" => "http://www.example.com/2", "rel" => "self" },
          ],
        },
      }
      page3 = {
        "results" => %w[foo3 bar3],
        "total" => 6,
        "current_page" => 3,
        "pages" => 3,
        "page_size" => 2,
        "_response_info" => {
          "status" => "ok",
          "links" => [
            { "href" => "http://www.example.com/2", "rel" => "previous" },
            { "href" => "http://www.example.com/3", "rel" => "self" },
          ],
        },
      }
      @p1_response = double(
        body: page1.to_json,
        status: 200,
        headers: {
          link: '<http://www.example.com/1>; rel="self", <http://www.example.com/2>; rel="next"',
        },
      )
      @p2_response = double(
        body: page2.to_json,
        status: 200,
        headers: {
          link: '<http://www.example.com/2>; rel="self", <http://www.example.com/3>; rel="next", <http://www.example.com/1>; rel="previous"',
        },
      )
      @p3_response = double(
        body: page3.to_json,
        status: 200,
        headers: {
          link: '<http://www.example.com/3>; rel="self", <http://www.example.com/1>; rel="previous"',
        },
      )

      @client = double
      allow(@client).to receive(:get_list).with("http://www.example.com/1").and_return(ApiAdaptor::ListResponse.new(@p1_response, @client))
      allow(@client).to receive(:get_list).with("http://www.example.com/2").and_return(ApiAdaptor::ListResponse.new(@p2_response, @client))
      allow(@client).to receive(:get_list).with("http://www.example.com/3").and_return(ApiAdaptor::ListResponse.new(@p3_response, @client))
    end

    describe "accessing next page" do
      it "should allow accessing the next page" do
        resp = ApiAdaptor::ListResponse.new(@p1_response, @client)
        expect(resp.has_next_page?).to be_truthy
        expect(resp.next_page["results"]).to eq %w[foo2 bar2]
      end

      it "should return nil with no next page" do
        resp = ApiAdaptor::ListResponse.new(@p3_response, @client)
        expect(resp.has_next_page?).to be_falsy
        expect(resp.next_page).to be_nil
      end

      it "should memoize the next_page" do
        resp = ApiAdaptor::ListResponse.new(@p1_response, @client)
        first_call = resp.next_page

        allow(@client).to receive(:get_list).with("http://www.example.com/2").and_return(ApiAdaptor::ListResponse.new(@p2_response, @client))
        second_call = resp.next_page
        expect(first_call).to eq second_call
      end
    end

    describe "accessing content across all pages" do
      before :each do
        @response = ApiAdaptor::ListResponse.new(@p1_response, @client)
      end

      it "should allow iteration across multiple pages" do
        expect(@response.with_subsequent_pages.count).to eq 6
        expect(@response.with_subsequent_pages.to_a).to eq %w[foo1 bar1 foo2 bar2 foo3 bar3]
        expect(@response.with_subsequent_pages.select { |s| s =~ /foo/ }).to eq %w[foo1 foo2 foo3]
      end

      it "should not load a page multiple times" do
        allow(@client).to receive(:get_list).with("http://www.example.com/2").once.and_return(ApiAdaptor::ListResponse.new(@p2_response, @client))
        allow(@client).to receive(:get_list).with("http://www.example.com/3").once.and_return(ApiAdaptor::ListResponse.new(@p3_response, @client))

        3.times do
          @response.with_subsequent_pages.to_a
        end
      end

      it "should work with a non-paginated response" do
        data = {
          "results" => %w[foo1 bar1],
          "total" => 2,
          "_response_info" => {
            "status" => "ok",
          },
        }
        response = ApiAdaptor::ListResponse.new(double(body: data.to_json, status: 200, headers: {}), nil)

        expect(response.with_subsequent_pages.to_a).to eq %w[foo1 bar1]
      end
    end
  end
end