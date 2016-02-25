# Change Log
All changes to the SDK will be documented in this file.
This project follows the [Semantic Versioning](http://semver.org) style.

## [Unreleased]
### Deprecated
- `configValueForKeyPath:` use `configValueForKeyPath:fallbackValue:` with `nil` for the 2nd argument instead.
- `featureFlagForKey:` use `featureFlagForKey:fallback:` instead.

### Added
- `CFGConfigValueFetcher` for handling all methods associated with configuration and fallbacks.
