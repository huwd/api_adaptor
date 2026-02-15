## [1.0.0] - 2026-02-15

### Added
- YARD documentation for all public APIs (100% coverage)
- YARD documentation deployment to GitHub Pages
- CLAUDE.md development guide for AI assistants and contributors
- rubocop-yard plugin for documentation linting
- API Documentation section in README with links to hosted docs
- Development section in README with testing, coverage, and documentation commands
- Troubleshooting section in README for common issues
- Badges in README for CI status, gem version, and documentation

### Changed
- README enhanced with wikidata_adaptor best practices
- Default Rake task now includes YARD documentation generation
- RuboCop now enforces documentation standards via rubocop-yard
- GitHub Actions updated to use consistent SHA pinning across all workflows
- All development dependencies updated to latest compatible versions

### Fixed
- Standardized GitHub Actions versions across all workflows
- Updated ruby/setup-ruby to v1.288.0 in all workflows
- Updated rubygems/release-gem to v1.1.2 in release workflow
- Updated actions/configure-pages to v5.0.0 in pages workflow
- Updated actions/upload-pages-artifact to v4.0.0 in pages workflow
- Updated actions/deploy-pages to v4.0.5 in pages workflow
- Fixed invalid date format in CHANGELOG (2025-31-01 → 2025-01-31)

## [0.1.0] - 2025-01-31

- Improvements to 307, 308 redirect behaviour
- Greater configuration over redirect behaviour
- Add CI/CD to Rubygems
- Test against Ruby v4.0

## [0.0.2] - 2024-14-01

- Improvements to CI/CD
  - Enable CodeQL
  - Enable Dependabot
  - Enable Rubocop Testing
  - Enable unit testing against Ruby v3.2, v3.3, v3.4

## [0.0.1] - 2023-06-01

- Initial release

## [0.0.0] - 2023-05-29

- Bootstrapping
