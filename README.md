# ApiAdaptor

A basic adaptor to send HTTP requests and parse the responses.
Intended to bootstrap the quick writing of Adaptors for specific APIs, without having to write the same old JSON request and processing time and time again.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add api_adaptor

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install api_adaptor

## Usage

TODO: Write usage instructions here

## Environment variables

User Agent is populated with a default string.
See .env.example.

For instance if you provide:
```
APP_NAME=test_app
APP_VERSION=1.0.0
APP_CONTACT=contact@example.com
```

User agent would read
```
test_app/1.0.0 (contact@example.com)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/huwd/api_adaptor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/huwd/api_adaptor/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ApiAdaptor project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/huwd/api_adaptor/blob/main/CODE_OF_CONDUCT.md).
