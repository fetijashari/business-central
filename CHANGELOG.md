# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- Enforce TLS 1.2 minimum and explicit certificate verification (`VERIFY_PEER`) on all HTTP connections
- Filter sensitive headers (Authorization, Cookie, Set-Cookie, X-Api-Key) from debug output
- Replace dynamic `Object.const_get` with a frozen HTTP method whitelist to prevent method injection
- Validate all URLs require HTTPS at client initialization to prevent SSRF
- Freeze all string constants to prevent runtime mutation
- Add `frozen_string_literal: true` pragma to main entry point

### Fixed
- `Picture.update` now fetches the correct picture by ID instead of calling `find_all`, which returned an array and produced an incorrect etag
- `Attachments.update` now sends the real etag in `If-Match` instead of the string `'application/json'`
- `Attachments.update` now sends `application/octet-stream` content type for binary content uploads
- `Attachments.destroy` now fetches the etag before deleting instead of sending an empty string
- `ApiException` now passes the message to `StandardError` so `.message` and `.to_s` work correctly in rescue blocks
- `Base#method_missing` no longer mutates `@object_path` in place; chaining returns a new instance, preventing state corruption when reusing objects
- `WebService#patch` accepts a proper positional hash for params alongside the new `etag:` keyword
- OAuth2 error handling now correctly extracts error codes from the response body when the `oauth2` gem wraps them in a different structure (compatibility with oauth2 2.0.18+)
- `MiniTest::Mock` updated to `Minitest::Mock` for compatibility with minitest 5.25+

### Added
- `FilteredDebugOutput` class for safe debug logging without credential exposure
- Configurable `open_timeout` (default 30s) and `read_timeout` (default 60s) on the client
- Configurable `debug_output` target (defaults to `$stdout`)
- Optional `etag:` parameter on `Base#update`, `Base#destroy`, `WebService#patch`, and `WebService#delete` to skip the redundant GET request when the etag is already known
- `SSL_OPTIONS` and `HTTP_METHODS` frozen constants on `Request`
- GitHub Actions CI workflow with Ruby 3.2, 3.3, 3.4 matrix and Rubocop lint job

### Changed
- `@object_path` is frozen after initialization; `method_missing` returns new `Base` instances instead of mutating self
- `Net::HTTP.new` replaced with `Net::HTTP.start` block for proper connection lifecycle management
- OAuth2 client instance is now memoized
- Upgraded `oauth2` gem to 2.0.18 (Ruby 3.4 support)
- Upgraded `minitest` to ~> 5.25, `minitest-reporters` to ~> 1.7, `rubocop` to ~> 1.81
- Updated `.ruby-version` from 2.7.4 to 3.2.2
- CI matrix updated from Ruby 2.6/2.7 to 3.2/3.3/3.4

## [2.0.0] - 2022-10-17

### Changed
- Upgraded OAuth2 dependency to ~> 2
- Used Ruby refinements instead of monkey-patching the String class

## [1.0.0] - 2019-01-01

### Added
- Initial release
- Basic and OAuth2 authentication
- CRUD operations for Business Central entities
- OData web service support
- Dynamic method chaining for resource discovery
