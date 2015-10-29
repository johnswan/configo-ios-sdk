//
//  Configo.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 16/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^CFGCallback)(NSDictionary *rawConfig, NSArray *featuresList);

FOUNDATION_EXPORT NSString *const ConfigoConfigurationLoadCompleteNotification;
FOUNDATION_EXPORT NSString *const ConfigoConfigurationLoadErrorNotification;
FOUNDATION_EXPORT NSString *const ConfigoNotificationUserInfoErrorKey;
FOUNDATION_EXPORT NSString *const ConfigoNotificationUserInfoRawConfigKey;
FOUNDATION_EXPORT NSString *const ConfigoNotificationUserInfoFeaturesListKey;

typedef NS_ENUM(NSUInteger, CFGConfigLoadState) {
    CFGConfigNotAvailable = 0,
    CFGConfigLoadedFromStorage,
    CFGConfigLoadingInProgress,
    CFGConfigLoadedFromServer,
    CFGConfigFailedLoadingFromServer,
};

@interface Configo : NSObject

@property (nonatomic, readonly) CFGConfigLoadState state;
@property (nonatomic) BOOL dynamicallyRefreshValues;

+ (NSString *)sdkVersionString;

+ (void)initWithDevKey:(NSString *)devKey appId:(NSString *)appId;
+ (void)initWithDevKey:(NSString *)devKey appId:(NSString *)appId callback:(CFGCallback)callback;
+ (instancetype)sharedConfigo;

- (void)setCallback:(CFGCallback)callback;

- (void)pullConfig;
- (void)pullConfig:(CFGCallback)callback;

- (void)forceRefreshValues;

- (void)setCustomUserId:(NSString *)userId;
- (void)setCustomUserId:(NSString *)userId userContext:(NSDictionary *)context;
- (void)setCustomUserId:(NSString *)userId userContext:(NSDictionary *)context error:(NSError *)err;
- (void)setUserContext:(NSDictionary *)context;
- (void)setUserContextValue:(id)value forKey:(NSString *)key;

- (NSDictionary *)rawConfig;
- (id)configValueForKeyPath:(NSString *)keyPath;

/**
 *  @return NSArray containing a list of feature keys (NSString) that are "on" for the user (can be empty).
 */
- (NSArray *)featuresList;

/**
 *  Feature flag for a given key.
 *  @param key that identifies the feature.
 *  @return The flag found in the config, false if not present.
 */
- (BOOL)featureFlagForKey:(NSString *)key;

/** For testing purposes */
#ifdef DEBUG
+ (NSString *)developmentDevKey;
+ (NSString *)developmentAppId;
#endif

@end
