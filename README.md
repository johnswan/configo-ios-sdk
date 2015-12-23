## Getting Started
1. Three options to get the SDK:
  1. Download the SDK from [here](https://s3.eu-central-1.amazonaws.com/configo.io/Framework/ConfigoSDK-0.3.7-framework.zip).
  2. Get the compiled version from the [repo](https://github.com/configo-io/configo-ios-sdk/tree/master/ConfigoSDK/Compiled%20Framework).
  3. Clone the repo and compile a version yourself using the `Configo-Universal` target.
  4. CocoaPods `pod etc/etc`
  5. Add the ConfigoSDK.xcodeproj as a subproject in your Xcode workspace.
2. Configo has the following built-in framework dependencies (Project Settings -> General Tab -> Linked Frameworks and Libraries -> +):
  ```
  SystemConfiguration.framework
  CoreTelephony.framework
  ```
  
3. Added the following Linker flags (found in Project Settings -> "Build Settings" tab -> "Other Linker Flags")
  
  ```
  -ObjC
  -all_load
  ```
  
4. In your app delegate, add the following import: 
  
  ```objective-c
  #import <ConfigoSDK/ConfigoSDK.h>
  ```
5. Add the following line in your `application:didFinishLaunchingWithOptions:` method with your API key and developer key (your keys can be found in the dashboard):

  ```objective-c
  [Configo initWithDevKey: @"YOUR_DEV_KEY" appId: @"YOUR_APP_ID"];
  ```
  
Optionally a block of code (i.e. `callback`) can be passed upon initialization, the block will be executed once the the loading process is complete:

  ```objective-c
  [Configo initWithDevKey: @"YOUR_DEV_KEY" appId: @"YOUR_APP_ID" callback: ^(NSError *err, NSDictionary *config, NSArray *features) {
    if(err) {
      NSLog(@"Failed to load config");
    } else {
      NSLog(@"The config was loaded: %@, features list: %@", config, features);
    }
  }];
  ```
  
<pre>
<b>NOTE:</b> The initialization should be called only once in the lifetime of the app. It has no effect on any consecutive calls.
</pre>

## Target Users
All users will be tracked as anonymous users unless a custom id and attributes are set.

Anonymous users can be segmented by their device attributes:
* Platform (OS)
* System Version (OS Version)
* Device Model
* Screen Resolution
* Application Name
* Application Identifier
* Application Version
* Application Build Number
* Connection Type (WiFi/Cellular)
* Carrier Name
* Device Language
* Time Zone
* Location (Country)

Identifying and segmenting users for targeted configurations can be done with the following:

* Passing a user identifier such as an email or a username (We advise using a unique value):

```objective-c
[[Configo sharedInstance] setCustomUserId: @"email@example.com"];
```

* Passing user context that can give more specific details about the user and targeting the user more precisely, using either of two ways:
  Passing an `NSDictionary`:
  
  ```objective-c
  [[Configo sharedInstance] setUserContext: @{@"key1" : @"value1", @"key2": @"value2"}];
  ```
  
  Setting every attribute individually (in different classes through out the app):
  
  ```objective-c
  [[Configo sharedInstance] setUserContextValue: @"value1" forKey: @"key1"];
  [[Configo sharedInstance] setUserContextValue: @"value2" forKey: @"key2"];
  ```
  
All values set in the `userContext` must be JSON compatible ([Apple Docs][https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSJSONSerialization_Class/]):
* `NSDictionary` or `NSArray` (All objects must be JSON compatible as well)
* `NSString`
* `NSNumber` (non NaN or infinity)
* `NSNull`

## Access Configurations
Configurations are the core of Configo.io and retrieving it is easy:

```objective-c
[[Configo sharedInstance] configValueForKeyPath: @"configKey" fallbackValue: @"fallbackString"];
```

<pre>
<b>NOTE:</b> The fallback value will be returned if an error was encountered or the configuration was not found.
</pre>

The configuration is stored in a JSON document form and retrieved by the SDK as an `NSDictionary` collection.

Accessing the configuration value can be done using dot notation and brackets, e.g.:
In a JSON of the form:

```json
{
  "object": {
    "array": [1,2,3]
  }
  ...
}
```

The second value in the array can be accessed like so:

```objective-c
[[Configo sharedInstance] configValueForKeyPath: @"object.array[1]"];
```

Alternatively, the configuration `NSDictionary` can be accessed directly by calling `rawConfig`.

## Feature Flags
Feature flags can be checked like so:

```objective-c
[[Configo sharedInstance] featureFlagForKey: @"cool_feature" fallback: YES];
```

<pre>
<b>NOTE:</b> The fallback BOOL will be returned if an error occurred or the feature was not found.
</pre>

The full list of the current user's active features can be retrieved using `featuresList`.

## Trigger Refresh

Configo constantly synchronizes with the dashboard upon app launch and by using the push mechanism. Configo looks out for any local changes that need to be synchronized and updates accordingly.

Sometimes a manual refresh of the configurations is required (with an optional `callback`):

```objective-c
[[Configo sharedInstance] pullConfig: ^(NSError *err, NSDictionary *config, NSArray *features) {
      ...
}];
```

<pre>
<b>NOTE:</b> The callback set here will only be executed once, when that specific call was made. It will have no effect on the callback set using the `setCallback:` method.
</pre>

## Dynamic Configuration Refresh
The configuration is updated and loaded every time the app opens, to avoid inconsistency at runtime. The configuration will be updated at runtime in the following scenarios:

1. Calling `pullConfig:` with a valid `callback`.
2. Setting `dynamicallyRefreshValues` to `YES`.
3. Calling `forceRefreshValues`.

## SDK Events
Configo's operational state can be retrieved using several methods:

1. NSNotification
2. callbacks
3. Polling for state


##### Notifications

Every time a configuration is updated an `NSNotification` is triggered.

* If the update was successful an `ConfigoConfigurationLoadCompleteNotification` will be broadcast with a `userInfo` containing values under the keys `ConfigoNotificationUserInfoRawConfigKey` and `ConfigoNotificationUserInfoFeaturesListKey` with the config and features list respectively.
* If an error occurred an `ConfigoConfigurationLoadErrorNotification` will be broadcast with a `userInfo` containing the error under the key `ConfigoNotificationUserInfoErrorKey`.


##### Callbacks

Using a Objective-C `blocks` is a convenient way to execute code in response to events. Configo expects all blocks to be of the `CFGCallback` type with the following definition:

```objective-c
typedef void(^CFGCallback)(NSError *error, NSDictionary *rawConfig, NSArray *featuresList);
```

a callback can be set upon initialization: `+ initWithDevKey:appId:callback:`

Or any time later using the `setCallback:` method. This will replace the callback set upon initialization.

If a manual configuration refresh is triggered an optional callback can be set as well `pullConfig:`. This will set a "temporary" callback that will only be called once when the manual refresh is complete. This will not affect the "main" callbacks set upon initialization or by `setCallback:`.

<pre>
<b>NOTE:</b> the "main" callback will be executed as well (if set).
</pre>


##### Configo State

Configo also holds a property named state that can hold either of the following values:

<pre>
//There is no config available.
<b>CFGConfigNotAvailable</b>
//The config was loaded from local storage (possibly outdated).
<b>CFGConfigLoadedFromStorage</b>
//The config is being loaded from the server. If there is an old, local config - it is still avaiable to use.
<b>CFGConfigLoadingInProgress</b>
//The config is has being loaded from the server and is ready for use. Might not be active if dynamicallyRefreshValues is false.
<b>CFGConfigLoadedFromServer</b>
//An error was encountered when loading the config from the server (Possibly no config is available).
<b>CFGConfigFailedLoadingFromServer</b>
</pre>
