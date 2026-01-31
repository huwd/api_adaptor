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

## Releasing

Publishing is handled by GitHub Actions when you push a version tag.

- RubyGems publishing uses **Trusted Publishing (OIDC)** via `rubygems/release-gem`
- Ensure `api_adaptor` is configured on RubyGems.org with this repository/workflow as a trusted publisher.
- Bump `ApiAdaptor::VERSION` in `lib/api_adaptor/version.rb`.
- Tag the release as `vX.Y.Z` (must match `ApiAdaptor::VERSION`) and push the tag:

```shell
git tag v0.1.1
git push origin v0.1.1
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

### Redirects (3xx)

Some APIs return a `3xx` response (commonly `307`/`308`) with a `Location` header that points to the “real” URL.
`ApiAdaptor::JsonClient` follows these redirects in a controlled way so callers consistently receive a final JSON response.

#### Defaults

- Redirects are followed for `GET`/`HEAD` when the status is `301`, `302`, `303`, `307`, or `308`.
- `max_redirects` defaults to `3`.
- Cross-origin redirects (scheme/host/port change) are allowed by default, but credentials are **not** forwarded.
- Non-GET requests (`POST`, `PUT`, `PATCH`, `DELETE`) do **not** follow redirects by default.

#### Configuration

You can configure redirect behaviour by passing options into your `ApiAdaptor::Base` subclass (they are forwarded to `ApiAdaptor::JsonClient`):

```ruby
client = MyApi.new(
  "https://example.com",
  max_redirects: 3,
  allow_cross_origin_redirects: true,
  forward_auth_on_cross_origin_redirects: false,
  follow_non_get_redirects: false
)

client.get_json("https://example.com/some/endpoint.json")
```

Or, if you are using `ApiAdaptor::JsonClient` directly:

```ruby
client = ApiAdaptor::JsonClient.new(
  bearer_token: "SOME_BEARER_TOKEN",
  max_redirects: 3,
  allow_cross_origin_redirects: true,
  forward_auth_on_cross_origin_redirects: false
)

client.get_json("https://example.com/some/endpoint.json")
```

#### Security: auth and cross-origin redirects

Following redirects across origins can accidentally leak credentials (for example `Authorization` bearer tokens) to an unexpected host.
To reduce risk:

- By default, when the redirect target is cross-origin, `Authorization` is stripped and basic auth is not applied.
- To completely prevent cross-origin redirects, set `allow_cross_origin_redirects: false`.
- Only set `forward_auth_on_cross_origin_redirects: true` if you fully trust the redirect target.

#### Non-GET redirects (risk of replay)

Redirects for non-GET requests are risky because they may cause a request to be replayed (and potentially create duplicate side effects).
For that reason, redirect-following is disabled for non-GET requests by default.

If you do want to follow `307`/`308` for non-GET requests, you can opt in:

```ruby
client = MyApi.new(
  "https://example.com",
  follow_non_get_redirects: true
)

client.post_json("https://example.com/some/endpoint.json", { "a" => 1 })
```

#### Handling redirect failures

You can rescue these redirect-specific exceptions:

- `ApiAdaptor::TooManyRedirects` (exceeded `max_redirects`)
- `ApiAdaptor::RedirectLocationMissing` (a redirect response without a usable `Location`)

Example:

```ruby
begin
  client.get_json("https://example.com/some/endpoint.json")
rescue ApiAdaptor::TooManyRedirects, ApiAdaptor::RedirectLocationMissing => e
  # handle / log / retry / surface a friendly message
  raise e
end
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
This allows other applications that integrate the API Adaptor to easily mock out calls and receive representative data back.

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
