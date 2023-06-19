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
  class MyApi < ApiAdaptor::Base
    def base_url
      endpoint
    end
  end
```

Use your new class to create a client that can make HTTP requests to JSON APIs for:

### GET JSON

```ruby
client = MyApi.new
response = client.get_json("http://some.endpoint/json")
```

### POST JSON

```ruby
client = MyApi.new
response = client.post_json("http://some.endpoint/json", { "foo": "bar" })
```

### PUT JSON

```ruby
client = MyApi.new
response = client.put_json("http://some.endpoint/json", { "foo": "bar" })
```

### PATCH JSON

```ruby
client = MyApi.new
response = client.patch_json("http://some.endpoint/json", { "foo": "bar" })
```

### DELETE JSON

```ruby
client = MyApi.new
response = client.delete_json("http://some.endpoint/json", { "foo": "bar" })
```

### GET raw requests

you can also get a raw response from the API

```ruby
client = MyApi.new
response = client.get_raw("http://some.endpoint/json")
```

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
