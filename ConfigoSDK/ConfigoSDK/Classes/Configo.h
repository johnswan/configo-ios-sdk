//
//  Configo.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 16/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const ConfigoConfigurationLoadCompleteNotification;
FOUNDATION_EXPORT NSString *const ConfigoConfigurationLoadErrorNotification;
FOUNDATION_EXPORT NSString *const ConfigoNotificationUserInfoErrorKey;

typedef NS_ENUM(NSUInteger, CFGConfigLoadState) {
    CFGConfigNotAvailable = 0,
    CFGConfigLoadedFromStorage,
    CFGConfigLoadingInProgress,
    CFGConfigLoadedFromServer,
    CFGConfigFailedLoading,
};

@interface Configo : NSObject

@property (nonatomic, readonly) CFGConfigLoadState state;

+ (void)initWithDevKey:(NSString *)devKey appId:(NSString *)appId;
+ (instancetype)sharedConfigo;

- (void)pullConfig;

- (void)setCustomUserId:(NSString *)userId;
- (void)setCustomUserId:(NSString *)userId userContext:(NSDictionary *)context;
- (void)setCustomUserId:(NSString *)userId userContext:(NSDictionary *)context error:(NSError *)err;
- (void)setUserContextValue:(id)value forKey:(NSString *)key;

- (NSDictionary *)config;
- (id)configForKeyPath:(NSString *)keyPath;

@end
