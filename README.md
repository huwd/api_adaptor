# ApiAdaptor

A basic adaptor to send HTTP requests and parse the responses.
Intended to bootstrap the quick writing of Adaptors for specific APIs, without having to write the same old JSON request and processing time and time again.

## Installation

Install the gem and add to the application's Gemfile by executing:

```shell
bundle add api_adaptor
```

If bundler is not being used to manage dependencies, install the gem by executing:

```shell
gem install api_adaptor
```

## Usage

Use the ApiAdaptor as a base class for your API wrapper, for example:

```ruby
  class MyApi < ApiAdaptor::Base; end
```

Use your new class to create a client that can make HTTP requests to JSON APIs for:

```ruby
client = MyApi.new
client.get_json("http://some.endpoint/json")
client.post_json("http://some.endpoint/json", { "foo": "bar" })
client.put_json("http://some.endpoint/json", { "foo": "bar" })
client.patch_json("http://some.endpoint/json", { "foo": "bar" })
client.delete_json("http://some.endpoint/json", { "foo": "bar" })
```

You can also get a raw response from the API

```ruby
client.get_raw("http://some.endpoint/json")
```

### Conventional usage

An example of how to use this repository to bootstrap an API can be found in the [WikiData REST adaptor](https://github.com/huwd/wikidata_adaptor) it was built for.

A REST API module can be created with:

```ruby
module MyApiAdaptor
  # Wikidata REST API class
  class RestApi < ApiAdaptor::Base
    def get_foo(foo_id)
      get_json("#{endpoint}/foo/#{CGI.escape(foo_id)}")
    end
  end
end
```

and can be wrapped in a top level module:

```ruby
module MyApiAdaptor
  class Error < StandardError; end

  def self.rest_endpoint
    ENV["MYAPI_REST_ENDPOINT"] || "https://example.com"
  end

  def self.rest_api
    MyApiAdaptor::RestApi.new(rest_endpoint)
  end
end
```

The intended convention is to have test helpers ship alongside the actual Adaptor code.
See [WikiData examples here](https://github.com/huwd/wikidata_adaptor/blob/main/lib/wikidata_adaptor/test_helpers/rest_api.rb).
This allows other applications that integrate the API Adaptor to easily mock out calls and recieve representative data back.

## Environment variables

User Agent is populated with a default string.
See .env.example.

For instance if you provide:

```bash
APP_NAME=test_app
APP_VERSION=1.0.0
APP_CONTACT=contact@example.com
```

User agent would read

```text
test_app/1.0.0 (contact@example.com)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/huwd/api_adaptor>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/huwd/api_adaptor/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ApiAdaptor project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/huwd/api_adaptor/blob/main/CODE_OF_CONDUCT.md).
