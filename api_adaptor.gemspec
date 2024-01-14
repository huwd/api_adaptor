# frozen_string_literal: true

require_relative "lib/api_adaptor/version"

Gem::Specification.new do |spec|
  spec.name = "api_adaptor"
  spec.version = ApiAdaptor::VERSION
  spec.authors = ["Huw Diprose"]
  spec.email = ["mail@huwdiprose.co.uk"]

  spec.summary = "A basic adaptor to send HTTP requests and parse the responses."
  spec.description = "A basic adaptor to send HTTP requests and parse the responses. Intended to bootstrap the quick writing of Adaptors for specific APIs, without having to write the same old JSON request and processing time and time again."
  spec.homepage = "https://github.com/huwd/api_adaptor"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/huwd/api_adaptor"
  spec.metadata["changelog_uri"] = "https://github.com/huwd/api_adaptor/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "addressable", "~> 2.8"
  spec.add_dependency "link_header", "~> 0.0.8"
  spec.add_dependency "rest-client", "~> 2.1"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "webmock", "~> 3.18"
end
