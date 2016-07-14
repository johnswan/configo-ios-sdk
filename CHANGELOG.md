# Change Log
All changes to the SDK will be documented in this file.
This project follows the [Semantic Versioning](http://semver.org) style.

## [Unreleased]
### Added
- `CFGNetworkController` tests for network reachability before making any request.


## [0.5.0] - 2016-06-27
### Deprecated
- `featuresList` use `featuresDictionary` instead.
- `ConfigoNotificationUserInfoFeaturesListKey` use `ConfigoNotificationUserInfoFeaturesDictionaryKey` instead.

### Added
- Clear all user context via `clearUserContext`.
- `featuresDictionary` returning an NSDicitionary containing key-value pairs of the format `{"<featureKey" : <NSNumber boolean>}`.

### Changed
- `CFGCallback` code block typedef now recieves featuresDictionary NSDictionary instead of the featureList NSArray.
- Logging format.

### Internal
#### Changed 
- `getConfig` v2 only.

## [0.4.4] - 2016-03-02 
### Deprecated
- `configValueForKeyPath:` use `configValueForKeyPath:fallbackValue:` with `nil` for the 2nd argument instead.
- `featureFlagForKey:` use `featureFlagForKey:fallback:` with `NO` for the 2nd argument instead.
- `- setLoggingLevel:` use `+ setLoggingLevel:` (static) instead.

### Changed
- The Configo callback block will be executed when done loading from the server only (Was called when loaded from storage as well).

### Added
- `+ setLoggingLevel:` for changing the log level before the init.

### Fixed
- Bug related to feature flags 'off' for certain groups but 'on' in general always comes back as 'off'. (API v2)
- Logging level bug causing all logs to be logged.

### Internal / Private Changes
#### Added
- `CFGConfigValueFetcher` for handling all methods associated with configuration and fallbacks.

#### Changed
- `getConfig` v1 -> v2 for detailed feature flags.
