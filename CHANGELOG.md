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
- Add `SECURITY.md` with vulnerability reporting policy and security best practices

### Fixed
- OAuth2 client now uses `auth_scheme: :request_body` for Azure AD compatibility (v2.x gem changed the default to `:basic_auth` which Microsoft rejects)
- `Picture.update` now fetches the correct picture by ID instead of calling `find_all`, which returned an array and produced an incorrect etag
- `Attachments.update` now sends the real etag in `If-Match` instead of the string `'application/json'`
- `Attachments.update` now sends `application/octet-stream` content type for binary content uploads
- `Attachments.destroy` now fetches the etag before deleting instead of sending an empty string
- `ApiException` now passes the message to `StandardError` so `.message` and `.to_s` work correctly in rescue blocks
- `Base#method_missing` no longer mutates `@object_path` in place; chaining returns a new instance, preventing state corruption when reusing objects
- `WebService#object` now returns a new instance instead of mutating self, preventing state corruption from parallel or repeated use
- Replaced deprecated `URI::RFC2396_Parser` with `URI::DEFAULT_PARSER` for URL encoding
- OAuth2 error handling now correctly extracts error codes from the response body (compatibility with oauth2 2.0.18+)
- Malformed JSON responses now raise `ApiException` instead of raw `JSON::ParserError`
- Fixed `LICENSE.txt` copyright placeholder

### Added
- Structured logging framework with configurable `logger` option on the client
- HTTP request logging at DEBUG level with method, sanitized URL, and elapsed time
- OAuth2 auth event logging (authorize, token, refresh) at INFO level
- Query parameter filtering in logs to prevent PII exposure
- Rate limiting (429) handling with automatic retry and configurable exponential backoff
- OData pagination parameters: `$top`, `$skip`, `$orderby`, `$select`, `$expand`
- Response extraction of `@odata.nextLink` for cursor-based pagination
- OAuth2 scope management with configurable `oauth2_scope` option
- Environment and sandbox support via `environment`, `tenant_id`, and `api_version` options
- New exception types: `ForbiddenException`, `ConflictException`, `BadRequestException`, `UnprocessableEntityException`, `RateLimitException`
- BC-specific error code mapping (EditConflict, Permission codes)
- Response status helpers: `bad_request?`, `forbidden?`, `conflict?`, `unprocessable?`, `rate_limited?`, `server_error?`
- Input validation for IDs (nil/blank rejection) and params (type checking)
- Known BC entity awareness: `KNOWN_BC_ENTITIES` constant, accurate `respond_to_missing?`, warning logs for unknown entities
- Optional `etag:` parameter on `update`, `destroy`, `WebService#patch`, and `WebService#delete` to skip redundant GET requests
- `FilteredDebugOutput` class for safe debug logging without credential exposure
- Configurable `open_timeout`, `read_timeout`, `max_retries`, `retry_delay`, and `debug_output` on the client
- `SECURITY.md` with vulnerability reporting process and security guidance
- `CHANGELOG.md`
- GitHub Actions CI workflow with Ruby 3.2, 3.3, 3.4 matrix and Rubocop lint job

### Changed
- `@object_path` is frozen after initialization; `method_missing` returns new instances
- `Net::HTTP.new` replaced with `Net::HTTP.start` block for proper connection lifecycle
- `WebService#object` returns a new instance instead of mutating self
- `respond_to_missing?` returns true only for known entities and concrete classes
- OAuth2 client instance is now memoized
- Upgraded `oauth2` to 2.0.18, `minitest` to ~> 5.25, `minitest-reporters` to ~> 1.7, `rubocop` to ~> 1.81
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
