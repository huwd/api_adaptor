# frozen_string_literal: true

RSpec.describe ApiAdaptor do
  let(:client) { ApiAdaptor::Base.new }
  let(:github_pages_url) { "https://huwd.github.io/api_adaptor/" }

  it "can request valid JSON from a client" do
    file_data = File.join(__dir__, "../fixtures/v1/integration/foo.json")
    json = client.get_json("#{github_pages_ur}/foo.json")
    expect(json.parsed_content).to eq(file_data)
  end
end
