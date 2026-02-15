# CLAUDE.md - Developer Guide for api_adaptor

This guide is for AI assistants and human contributors working on api_adaptor. It provides context about the project's architecture, conventions, and development workflow.

## Overview

**api_adaptor** is a Ruby gem that provides a basic HTTP client adaptor for JSON APIs. It handles common patterns like request/response parsing, redirects, error handling, and pagination, allowing developers to quickly build API clients without repetitive boilerplate.

### Key Features

- JSON request/response handling with automatic parsing
- Configurable redirect handling (cross-origin, non-GET requests)
- Bearer token and basic authentication support
- Pagination support via `ListResponse`
- Cache-Control header parsing
- Comprehensive exception hierarchy for HTTP errors
- Thread-safe connection pooling via rest-client

### Architecture

- **JSONClient**: Core HTTP client with redirect handling and authentication
- **Base**: Abstract base class for building API-specific clients
- **Response/ListResponse**: Wrapper classes for parsed responses
- **Headers**: Manages request headers including User-Agent
- **Variables**: Environment variable configuration for app metadata
- **Exceptions**: HTTP error hierarchy

## Commands

### Development

```bash
bundle install              # Install dependencies
bundle exec rspec           # Run tests
bundle exec rubocop         # Run linter
bundle exec rake            # Run tests + linter + generate docs (default)
```

### Documentation

```bash
bundle exec yard            # Generate YARD documentation to doc/
bundle exec yard server     # Preview docs at http://localhost:8808
bundle exec yard stats      # View documentation coverage
```

### Coverage

```bash
bundle exec rspec           # Generates coverage report
open coverage/index.html    # View coverage report
```

### Release

```bash
# Manual release (not recommended - use GitHub Actions)
bundle exec rake release    # Build gem, create git tag, push to RubyGems

# Automated release (recommended)
git tag v1.0.0              # Create version tag
git push origin v1.0.0      # Push tag to trigger release workflow
```

## Project Structure

### Core Files

```
lib/
├── api_adaptor.rb                  # Main entry point, loads all components
├── api_adaptor/
│   ├── version.rb                  # VERSION constant
│   ├── json_client.rb              # HTTP client with JSON parsing
│   ├── base.rb                     # Base class for API clients
│   ├── response.rb                 # Response wrapper with cache control
│   ├── list_response.rb            # Paginated response wrapper
│   ├── exceptions.rb               # HTTP exception hierarchy
│   ├── headers.rb                  # Header management
│   └── variables.rb                # Environment variable config
```

### Configuration

- `api_adaptor.gemspec` - Gem specification and dependencies
- `Rakefile` - Rake tasks (test, lint, docs)
- `.rubocop.yml` - RuboCop linting configuration
- `.yardopts` - YARD documentation configuration
- `.rspec` - RSpec test configuration

### Tests

```
spec/
├── spec_helper.rb                  # Test configuration with SimpleCov
├── api_adaptor/
│   ├── base_spec.rb                # Base class tests
│   ├── exceptions_spec.rb          # Exception handling tests
│   ├── headers_spec.rb             # Header tests
│   ├── json_client_spec.rb         # Core client tests
│   ├── list_response_spec.rb       # Pagination tests
│   ├── response_spec.rb            # Response wrapper tests
│   └── variables_spec.rb           # Environment variable tests
└── fixtures/                       # Test fixtures including foo.json
```

### CI/CD

```
.github/workflows/
├── ci.yml                          # Main CI (RSpec tests)
├── quality-checks.yml              # RuboCop linting
├── release.yml                     # Automated gem release
├── pages.yml                       # Deploy fixtures to GitHub Pages
├── docs.yml                        # Deploy YARD docs to GitHub Pages
└── codeql.yml                      # Security scanning
```

## Testing Conventions

### Test Structure

- Use RSpec with descriptive contexts
- Mock HTTP requests with WebMock
- Use Timecop for time-sensitive tests
- Aim for ≥80% line coverage, ≥75% branch coverage

### Test Patterns

```ruby
# Good: Descriptive context and it blocks
describe JSONClient do
  describe "#get_json" do
    context "when request succeeds" do
      it "returns parsed JSON response" do
        # ...
      end
    end

    context "when request fails" do
      it "raises appropriate exception" do
        # ...
      end
    end
  end
end

# Good: Use WebMock for HTTP mocking
stub_request(:get, "https://example.com/api")
  .to_return(status: 200, body: '{"key": "value"}')

# Good: Use Timecop for time tests
Timecop.freeze(Time.utc(2024, 1, 1, 12, 0, 0)) do
  # ...
end
```

### Running Tests

```bash
bundle exec rspec                   # Run all tests
bundle exec rspec spec/api_adaptor/json_client_spec.rb  # Run specific file
bundle exec rspec spec/api_adaptor/json_client_spec.rb:42  # Run specific line
```

## Environment Variables

The gem reads app metadata from environment variables for User-Agent headers:

- `APP_NAME` - Application name (default: "Ruby ApiAdaptor App")
- `APP_VERSION` - Application version (default: "Version not stated")
- `APP_CONTACT` - Contact email/URL for API providers

### Example .env

```bash
APP_NAME=MyApiClient
APP_VERSION=2.1.0
APP_CONTACT=dev@example.com
```

These are accessed via `ApiAdaptor::Variables` methods.

## Git Standards

Never commit to main branch,
Always create a new branch with a sensible descriptive name and expect a Pull Request process.

You'll need to provide a good PR description that sums up any collected change.

## Commit Standards

Follows [GDS Git conventions](https://gds-way.digital.cabinet-office.gov.uk/standards/source-code/working-with-git.html#commits), informed by [chris.beams.io/posts/git-commit](https://chris.beams.io/posts/git-commit), [thoughtbot](https://thoughtbot.com/blog/5-useful-tips-for-a-better-commit-message), [mislav.net](https://mislav.net/2014/02/hidden-documentation/), and [Joel Chippindale's "Telling Stories Through Your Commits"](https://blog.mocoso.co.uk/posts/talks/telling-stories-through-your-commits/).

### Formatting

- **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)** — subject line format: `<type>[optional scope]: <description>`
- **Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`
- **Scope** — optional parenthetical context, e.g. `feat(labels):` or `fix(integration):`
- **Breaking changes** — indicated with `!` before the colon, e.g. `feat!:`, or a `BREAKING CHANGE:` footer
- **Subject line** — max 50 characters, no trailing period, imperative mood ("Add feature" not "Added feature")
- **Body** — separated from subject by a blank line, wrapped at 72 characters
- **Links supplement, not replace** — issue/PR links may go stale, so the message must stand on its own

### Content

- **Answer three questions**: Why is this change necessary? How does it address the issue? What side effects does it have?
- **Explain the "why"** — the code shows _how_; the commit message must capture _why_. Rationale and context are hard to reconstruct later
- **Note alternatives considered** — if you chose approach A over B, say so and why

### Structure

- **Atomic commits** — each commit is a self-contained, logical unit of work; avoid needing "and" in your subject line
- **Tell a story** — commits should be logically ordered so the history reads as a coherent narrative, not a jumbled log
- **Clean up before sharing** — revise commit history on feature branches before opening a PR

## Development Workflow

### TDD Approach (Recommended)

1. **Write failing test** - Define expected behavior
2. **Implement feature** - Write minimal code to pass test
3. **Refactor** - Improve code while keeping tests green
4. **Document** - Add YARD comments to public APIs
5. **Lint** - Run `bundle exec rubocop` and fix issues
6. **Commit** - Use conventional commit message

### Feature Development Cycle

```bash
# 1. Create feature branch
git checkout -b feature/add-retry-logic

# 2. Write test
# Edit spec/api_adaptor/json_client_spec.rb

# 3. Run test (should fail)
bundle exec rspec spec/api_adaptor/json_client_spec.rb

# 4. Implement feature
# Edit lib/api_adaptor/json_client.rb

# 5. Run test (should pass)
bundle exec rspec spec/api_adaptor/json_client_spec.rb

# 6. Run full test suite
bundle exec rake

# 7. Commit
git add .
git commit -m "feat(client): add retry logic for transient failures"

# 8. Push and create PR
git push origin feature/add-retry-logic
gh pr create
```

### Code Review Checklist

- [ ] Tests pass (`bundle exec rspec`)
- [ ] Linter passes (`bundle exec rubocop`)
- [ ] Coverage maintained (≥80% line, ≥75% branch)
- [ ] YARD documentation added for public APIs
- [ ] CHANGELOG.md updated (if applicable)
- [ ] Conventional commit message used

## Release Process

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking API changes (1.0.0 → 2.0.0)
- **MINOR**: New features, backward-compatible (1.0.0 → 1.1.0)
- **PATCH**: Bug fixes, backward-compatible (1.0.0 → 1.0.1)

### Release Checklist

1. **Update version** - Edit `lib/api_adaptor/version.rb`
2. **Update CHANGELOG** - Add entry with date in `CHANGELOG.md`
3. **Run full test suite** - `bundle exec rake` (includes tests, lint, docs)
4. **Commit changes** - `chore(release): prepare v1.0.0`
5. **Create git tag** - `git tag v1.0.0`
6. **Push tag** - `git push origin v1.0.0`
7. **GitHub Actions triggers** - Release workflow builds and publishes gem to RubyGems
8. **Verify release** - Check https://rubygems.org/gems/api_adaptor

### Automated Release

The `.github/workflows/release.yml` workflow handles:

- Building the gem
- Running tests
- Publishing to RubyGems (using `RUBYGEMS_API_KEY` secret)
- Creating GitHub release

## Documentation Standards

### YARD Comments

All public APIs must have YARD documentation:

```ruby
# Initializes a new JSON client
#
# @param options [Hash] Configuration options
# @option options [String] :bearer_token Bearer token for authentication
# @option options [Hash] :basic_auth Basic auth credentials (:user, :password)
# @option options [Integer] :timeout Request timeout in seconds (default: 4)
# @option options [Integer] :max_redirects Maximum redirects to follow (default: 3)
# @option options [Boolean] :allow_cross_origin_redirects Allow cross-origin redirects (default: true)
# @option options [Logger] :logger Custom logger instance
#
# @return [JSONClient] A new instance of JSONClient
#
# @example Basic usage
#   client = JSONClient.new(bearer_token: "abc123")
#
# @example With custom timeout
#   client = JSONClient.new(timeout: 10)
def initialize(options = {})
  # ...
end
```

### Documentation Commands

```bash
bundle exec yard stats --list-undoc  # Find undocumented methods
bundle exec yard server              # Preview docs locally
```

## Code Quality Standards

### Coverage Targets

- **Line Coverage**: ≥80% (current: 92.3%)
- **Branch Coverage**: ≥75% (current: 81.65%)

### RuboCop Configuration

- Follows standard Ruby style guide
- Custom cops enabled: `rubocop-yard` for documentation enforcement
- Configuration in `.rubocop.yml`

### Security

- Input validation at API boundaries
- Safe redirect handling with cross-origin protection
- No credential logging
- CodeQL security scanning enabled

## Common Tasks

### Adding a New Exception

1. Define exception in `lib/api_adaptor/exceptions.rb`
2. Add YARD documentation
3. Add test in `spec/api_adaptor/exceptions_spec.rb`
4. Update `json_client.rb` to raise exception where appropriate

### Adding a New Configuration Option

1. Add parameter to `JSONClient#initialize`
2. Document with YARD `@option` tag
3. Add instance variable and accessor
4. Add tests for new behavior
5. Update README with example

### Debugging HTTP Requests

```ruby
# Enable request/response logging
client = JSONClient.new(logger: Logger.new($stdout))
```

## Troubleshooting

### Tests Failing

```bash
# Run specific test
bundle exec rspec spec/api_adaptor/json_client_spec.rb:42

# Run with verbose output
bundle exec rspec --format documentation

# Check coverage
open coverage/index.html
```

### RuboCop Errors

```bash
# Auto-fix safe violations
bundle exec rubocop --auto-correct

# Fix all violations (less safe)
bundle exec rubocop --auto-correct-all
```

### YARD Documentation Issues

```bash
# Check for undocumented methods
bundle exec yard stats --list-undoc

# Validate YARD syntax
bundle exec yard --no-output
```

## Additional Resources

- **RubyGems**: https://rubygems.org/gems/api_adaptor
- **GitHub**: https://github.com/huwd/api_adaptor
- **YARD Docs**: https://huwd.github.io/api_adaptor/
- **Issues**: https://github.com/huwd/api_adaptor/issues

## Contact

- **Maintainer**: Huw Diprose
- **Email**: mail@huwdiprose.co.uk
- **License**: MIT
