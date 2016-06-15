//
//  Configo.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 16/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CFGLogLevel.h"

/**
 *	@brief A block to be executed after the config is loaded from the remote source.
 *  @param error                An optional error (NSError) if something went wrong, or <code>null</code> if everything went well.
 *	@param rawConfig            The config (NSDictionary) that was loaded.
 *	@param featuresDictionary	The features dictionary holding pairs of <code>{"<featureKey>" : <NSNumber boolean>}</code>.
 */
typedef void(^CFGCallback)(NSError *error, NSDictionary *rawConfig, NSDictionary *featuresDictionary);


/** The name of the notification that will be broadcast when the configuration is loaded successfully. */
FOUNDATION_EXPORT NSString *const ConfigoConfigurationLoadCompleteNotification;
/** The name of the notification that will be broadcast if the configuration remote loading failed. */
FOUNDATION_EXPORT NSString *const ConfigoConfigurationLoadErrorNotification;
/** The key of the error in the userInfo dictionary of the <code>ConfigoConfigurationLoadErrorNotification</code>. */
FOUNDATION_EXPORT NSString *const ConfigoNotificationUserInfoErrorKey;
/** The key of the config (NSDictionary) in the userInfo dictionary of the <code>ConfigoConfigurationLoadCompleteNotification</code> */
FOUNDATION_EXPORT NSString *const ConfigoNotificationUserInfoRawConfigKey;
/** The key of the features list (NSArray) in the userInfo dictionary of the <code>ConfigoConfigurationLoadCompleteNotification</code> */
FOUNDATION_EXPORT NSString *const ConfigoNotificationUserInfoFeaturesListKey __attribute__((deprecated("Use `ConfigoNotificationUserInfoFeaturesDictionaryKey` instead")));
/** The key of the features dictionary (NSDictionary) in the userInfo dictionary of the <code>ConfigoConfigurationLoadCompleteNotification</code> */
FOUNDATION_EXPORT NSString *const ConfigoNotificationUserInfoFeaturesDictionaryKey;

/**
 *  @brief The current load state of the config.
 */
typedef NS_ENUM(NSUInteger, CFGConfigLoadState) {
    ///There's no config available.
    CFGConfigNotAvailable = 0,
    ///The config was loaded from local storage (possibly outdated).
    CFGConfigLoadedFromStorage,
    ///The config is being loaded from the server. If there's an old, local config - it is still avaiable to use.
    CFGConfigLoadingInProgress,
    ///The config is has being loaded from the server and is ready for use. Might not be active if <i>dynamicallyRefreshValues</i> is false.
    CFGConfigLoadedFromServer,
    ///An error was encountered when loading the config from the server (possibly no config is available).
    CFGConfigFailedLoadingFromServer,
};


/**
 *	@brief The ConfigoSDK API. <i>Configo</i> class contains the <code>sharedConfigo</code> singleton used to initialize and access all of ConfigoSDK's functions.
 */
@interface Configo : NSObject

/** The current load state of the config */
@property (nonatomic, readonly) CFGConfigLoadState state;

/**
 *	@brief Determines if the config is automatically loaded as soon as it is retrieved from the server.
 *  @default (defaults to false).
 *  @discussion Triggering a manual refresh can be done with <code>forceRefreshValues</code>.
 */
@property (nonatomic) BOOL dynamicallyRefreshValues;

/** The SDK's version string. */
+ (NSString *)sdkVersion;

/**
 *	@brief The initialize call. Must be called first before using any of the SDK's functions.
 *  Subsequent calls to the SDK can be done using the <code>sharedConfigo</code> method.
 *  @warning Should be called only once per app run.
 *	@param devKey The developer key. Can be found in the dashboard.
 *	@param appId The application id. Can be found in the dashboard.
 */
+ (void)initWithDevKey:(NSString *)devKey appId:(NSString *)appId;

/**
 *	@brief The initialize call. Must be called first before using any of the SDK's functions.
 *  Subsequent calls to the SDK can be done using the <code>sharedConfigo</code> method.
 *  @warning Should be called only once per app run.
 *	@param devKey The developer key. Can be found in the dashboard.
 *	@param appId The application id. Can be found in the dashboard.
 *  @param callback An optional <code>CFGCallback</code> block that will be executed when the config loading process is complete. (Uses <code>setCallback:</code> behind the scenes)
 */
+ (void)initWithDevKey:(NSString *)devKey appId:(NSString *)appId callback:(CFGCallback)callback;

/**
 *	@brief The singleton accessor. Can only be accessed after instantiated with one of the <code>initWithDevKey:appId:</code> initialize methods.
 *	@return <code>Configo</code> instance
 */
+ (instancetype)sharedInstance;

/**
 *	@brief Set the logging level.
 *	@param level The level of the logs produced by the ConfigoSDK.
 */
- (void)setLoggingLevel:(CFGLogLevel)level DEPRECATED_MSG_ATTRIBUTE("use '+ setLoggingLevel:' instead.");
+ (void)setLoggingLevel:(CFGLogLevel)level;

/**
 *	@brief The callback that will be called once the config loading process is complete.
 *	@param callback	A block of code to execute.
 *  @discussion If no callback was set before, and there's new data available - the callback will be executed immediately with the cached data.
 */
- (void)setCallback:(CFGCallback)callback;

/** @brief Trigger pulling a config from the server. */
- (void)pullConfig;

/**
 *	@brief Trigger pulling a config with an optional callback block. This callback is different from the <code>setCallback:</code> they will both be called in this case.
 *	@param callback	A "use once" block of code to be executed when the config loading process is finished.
 */
- (void)pullConfig:(CFGCallback)callback;

/**
 *	@brief Referesh the config to the newest config that was retrieved from the source (If exists).
 */
- (void)forceRefreshValues;

/**
 *	@brief Pass the user's unique id from your system to Configo, to have more precise targeting.
 *	@param userId user's unique identifier.
 */
- (void)setCustomUserId:(NSString *)userId;

/**
 *	@brief Set the context/attributes associated with the user for more precise targeting.
 *	@param context An NSDictionary (JSON compaitable) with data about the user.
 *  @warning This will replace any existing <code>userContext</code> set previously by <code>setUserContextValue:forKey:</code>
 *  @return false if context cannot be converted to JSON, true otherwise.
 */
- (BOOL)setUserContext:(NSDictionary *)context;

/**
 *	@brief Set a specific context value associated with the user.
 *	@param value The value to be set as part of the user context (Must be JSON compaitable: <code>NSNumber, NSString, NSArray, NSDictionary, NSNull</code>).
 *	@param key The key to associate the value with.
 *  @return false if <code>value</code> can not be converted to JSON, true otherwise.
 */
- (BOOL)setUserContextValue:(id)value forKey:(NSString *)key;

/**
 *  @brief Clears all previously set userContext, essentially removing the user from its targeting groups.
 */
- (void)clearUserContext;

/**
 *	@brief The raw config
 *  @discussion Using <code>configValueForKeyPath:</code> is strongly advised, as the dictionary can be drilled with dot notation for easier config values retrieval.
 *	@return The config <code>NSDictionary</code>
 */
- (NSDictionary *)rawConfig;


- (id)configValueForKeyPath:(NSString *)keyPath DEPRECATED_MSG_ATTRIBUTE("Redundant, use 'configValueForKeyPath:fallbackValue:' instead");

/**
 *	@brief  Find a value specific to a keypath in the currently loaded config.
 *	@param keyPath The keypath to the config value, see discussion for usage.
 *	@param fallbackValue The value to be returned if no config is loaded or no value found for the specified <code>keyPath</code>.
 *	@return The value found in the config or the <code>fallbackValue</code> if not found.
 */
- (id)configValueForKeyPath:(NSString *)keyPath fallbackValue:(id)fallbackValue;

/**
 *  @return NSArray containing NSDictionary elements, each is a pair of feature key and enabled pair.
 */
- (NSArray *)featuresList DEPRECATED_MSG_ATTRIBUTE("Use `featuresDictionary` instead");

/**
 *  @return An NSDictionary holding pairs of <code>{"<featureKey>" : <NSNumber boolean>}</code>.
 */
- (NSDictionary *)featuresDictionary;

/**
 *  @brief Feature flag for a given key.
 *  @param key The string that identifies the feature.
 *  @return The flag found in the config, false if not present.
 */
- (BOOL)featureFlagForKey:(NSString *)key DEPRECATED_MSG_ATTRIBUTE("Redundant, use 'featureFlagForKey:fallback:' instead");

/**
 *	@brief Feature flag for a given key.
 *	@param key The string that identifies the feature.
 *	@param fallbackFlag	The fallback value that will be returned if no config is loaded or no value found for the specified <code>key</code>.
 *	@return The flag found in the config, if the key is not found the <code>fallbackFlag</code> will be returned.
 */
- (BOOL)featureFlagForKey:(NSString *)key fallback:(BOOL)fallbackFlag;

@end
