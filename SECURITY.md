# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x     | Yes                |
| < 2.0   | No                 |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

To report a security vulnerability, please email the maintainers with:

1. Description of the vulnerability
2. Steps to reproduce
3. Potential impact assessment
4. Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 5 business days
- **Fix release**: Within 30 days for critical issues

### Responsible Disclosure

We follow a 90-day responsible disclosure policy. If a fix is not available within 90 days, reporters may disclose the vulnerability publicly.

## Security Best Practices

When using this gem:

1. **Never hardcode credentials** - Use environment variables:
   ```ruby
   client = BusinessCentral::Client.new(
     username: ENV['BC_USERNAME'],
     password: ENV['BC_PASSWORD'],
     application_id: ENV['BC_APP_ID'],
     secret_key: ENV['BC_SECRET_KEY']
   )
   ```

2. **Never enable debug mode in production** - Debug output may include HTTP traffic details
3. **Use OAuth2 over Basic Auth** when possible
4. **Keep dependencies updated** - Run `bundle audit` regularly
5. **Use tenant-specific OAuth2 URLs** instead of the `/common` endpoint

## Dependencies

This gem depends on:
- `oauth2` - OAuth2 client implementation
- `net/http` - HTTP transport (Ruby stdlib)

We recommend running automated dependency vulnerability scanning in your CI pipeline.
