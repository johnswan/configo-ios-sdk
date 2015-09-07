//
//  CFGConfigoDataController.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 26/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "CFGConfigoDataController.h"
#import "CFGConfigoData.h"
#import "CFGFileManager.h"

#import <CoreTelephony/CTCarrier.h>

#import <NNLibraries/NNLibrariesEssentials.h>
#import <NNLibraries/UIDevice+NNAdditions.h>
#import <NNLibraries/NNReachabilityManager.h>
#import <NNLibraries/NSDictionary+NNAdditions.h>

static NSString *const kPOSTKey_deviceDetails = @"deviceDetails";
static NSString *const kPOSTKey_userContext = @"userContext";
static NSString *const kPOSTKey_customUserId = @"customUserId";

static NSString *const kPOSTKey_Udid = @"udid";
static NSString *const kPOSTKey_deviceDetails_deviceName = @"deviceName";
static NSString *const kPOSTKey_deviceDetails_carrierName = @"carrierName";
static NSString *const kPOSTKey_deviceDetails_deviceModel = @"deviceModel";
static NSString *const kPOSTKey_deviceDetails_os = @"os";
static NSString *const kPOSTKey_deviceDetails_osVersion = @"osVersion";
static NSString *const kPOSTKey_deviceDetails_deviceLanguage = @"deviceLanguage";
static NSString *const kPOSTKey_deviceDetails_screenSize = @"screenSize";
static NSString *const kPOSTKey_deviceDetails_bundleId = @"bundleId";
static NSString *const kPOSTKey_deviceDetails_appName = @"appName";
static NSString *const kPOSTKey_deviceDetails_appVersion = @"appVersion";
static NSString *const kPOSTKey_deviceDetails_appBuild = @"appBuildNumber";
static NSString *const kPOSTKey_deviceDetails_connectionType = @"connectionType";


@interface CFGConfigoDataController ()
@property (nonatomic, strong) CFGConfigoData *configoData;
@property (nonatomic) BOOL userContextChanged;
@property (nonatomic) BOOL customUserIdChanged;
@end

@implementation CFGConfigoDataController

#pragma mark - Init

- (instancetype)init {
    if(self = [super init]) {
        [self basicLoad];
    }
    return self;
}

- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    if(self = [super init]) {
        NSError *err = nil;
        _configoData = [[CFGFileManager sharedManager] loadConfigoDataForDevKey: devKey appId: appId error: &err];
        
        if(!_configoData) {
            NNLogDebug(@"ConfigoData file not found", err);
            [self basicLoad];
        } else {
            NNLogDebug(@"ConfigoData loaded from file", _configoData);
        }
    }
    return self;
}

- (instancetype)initWithConfigoData:(CFGConfigoData *)configoData {
    if(self = [super init]) {
        _configoData = [configoData copy];
    }
    return self;
}

- (void)basicLoad {
    _configoData = [[CFGConfigoData alloc] init];
    _configoData.udid = [UIDevice udidFromKeychain: nil];
}

#pragma mark - Instance Methods

- (NSDictionary *)configoDataForRequest {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSDictionary *deviceDetails = [self deviceDetails];
    NSString *udid = [UIDevice udidFromKeychain: nil];
    
    BOOL udidChanged = ![udid isEqualToString: _configoData.udid];
    BOOL deviceDetailsChanged = ![deviceDetails isEqualToDictionary: _configoData.deviceDetails];
    
    //Add UDID and CustomUserId to all requests (Identifiers)
    [dict nnSafeSetObject: _configoData.customUserId forKey: kPOSTKey_customUserId];
    dict[kPOSTKey_Udid] = udid;
    
    if(udidChanged || _customUserIdChanged) {
        NNLogDebug(@"UDID or CustomUserId changed, sending userContext and deviceDetails", nil);
        //If the UDID changed or the customUserId set context and details (i.e. new user)
        [dict nnSafeSetObject: _configoData.userContext forKey: kPOSTKey_userContext];
        [dict nnSafeSetObject: deviceDetails forKey: kPOSTKey_deviceDetails];
    } else if(_userContextChanged) {
        NNLogDebug(@"UserContext changed", nil);
        //If only the user context changed - we send it out
        [dict nnSafeSetObject: _configoData.userContext forKey: kPOSTKey_userContext];
    } else if(deviceDetailsChanged) {
        NNLogDebug(@"DeviceDetails changed", nil);
        //If any details changed - we send them
        [dict nnSafeSetObject: deviceDetails forKey: kPOSTKey_deviceDetails];
    }
    return dict;
}

- (BOOL)saveConfigoDataWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    return [self saveConfigoDataWithDevKey: devKey appId: appId error: nil];
}

- (BOOL)saveConfigoDataWithDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err {
    _customUserIdChanged = NO;
    _userContextChanged = NO;
    _configoData.deviceDetails = [self deviceDetails];
    _configoData.udid = [UIDevice udidFromKeychain: nil];
    BOOL success = [[CFGFileManager sharedManager] saveConfigoData: _configoData withDevKey: devKey appId: appId error: err];
    NNLogDebug(success ? @"ConfigoData save success" : @"ConfigoData save failed" , err ? *err : nil);
    return success;
}

#pragma mark - Getters

- (NSDictionary *)userContext {
    return _configoData.userContext;
}

#pragma mark - Setters

- (BOOL)setCustomUserId:(NSString *)customUserId {
    if(!customUserId && !_configoData.customUserId) {
        return NO;
    }
    
    if(![_configoData.customUserId isEqualToString: customUserId]) {
        _configoData.customUserId = customUserId;
        _customUserIdChanged = YES;
        return YES;
    }
    return NO;
}

- (BOOL)setUserContext:(NSDictionary *)userContext {
    if(!userContext && !_configoData.userContext) {
        return NO;
    }
    
    id validContext = [NNJSONUtilities makeValidJSONObject: userContext];
    if(![_configoData.userContext isEqualToDictionary: validContext]) {
        _configoData.userContext = validContext;
        _userContextChanged = YES;
        return YES;
    }
    
    return NO;
}

- (BOOL)setUserContextValue:(id)value forKey:(NSString *)key {
    if(!value || !key) {
        return NO;
    }
    
    BOOL retval = NO;
    id original = [_configoData.userContext objectForKey: key];
    if(original) {
        if(![original isEqual: value]) {
            [_configoData setUserContextValue: value forKey: key];
            retval = YES;
        }
    } else {
        [_configoData setUserContextValue: value forKey: key];
        retval = YES;
    }
    
    if(retval) {
        _userContextChanged = retval;
    }
    
    return retval;
}

#pragma mark - Helpers

- (NSDictionary *)deviceDetails {
    NSMutableDictionary *details = [NSMutableDictionary dictionary];
    
    NSString *deviceName = [[UIDevice currentDevice] name];
    NSString *deviceModel = nil;
    if([UIDevice isDeviceSimulator]) {
        deviceModel = @"SIMULATOR";
    } else {
        deviceModel = [[UIDevice currentDevice] model];
    }
    NSString *os = @"iOS";
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    CTCarrier *carrier = [[CTCarrier alloc] init];
    NSString *carrierName = [carrier carrierName] ? : @"NA"; //Not always available, e.g. iPad
    
    NSString *language = @"en";
    NSArray *preferredLanguages = [NSLocale preferredLanguages];
    if(preferredLanguages.count > 0) {
        language = preferredLanguages[0];
    }
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    NSInteger screenHeight = MAX(screenBounds.size.height, screenBounds.size.width);
    NSInteger screenWidth = MIN(screenBounds.size.height, screenBounds.size.width);
    NSString *screenSize = [NSString stringWithFormat: @"%lix%li", (long)screenHeight, (long)screenWidth];
    
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *appName = [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleNameKey];
    NSString *appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *buildNumber = [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey];
    
    NSString *connectionType = nil;
    if([[NNReachabilityManager sharedManager] isReachableViaWiFi]) {
        connectionType = @"WiFi";
    } else if([[NNReachabilityManager sharedManager] isReachableViaCellular]) {
        connectionType = @"Cellular";
    } else if([[NNReachabilityManager sharedManager] isReachable]) {
        connectionType = @"Unknown";
    }
    
    details[kPOSTKey_deviceDetails_deviceName] = deviceName;
    details[kPOSTKey_deviceDetails_carrierName] = carrierName;
    details[kPOSTKey_deviceDetails_deviceModel] = deviceModel;
    details[kPOSTKey_deviceDetails_os] = os;
    details[kPOSTKey_deviceDetails_osVersion] = osVersion;
    details[kPOSTKey_deviceDetails_deviceLanguage] = language;
    details[kPOSTKey_deviceDetails_screenSize] = screenSize;
    details[kPOSTKey_deviceDetails_bundleId] = bundleId;
    details[kPOSTKey_deviceDetails_appName] = appName;
    details[kPOSTKey_deviceDetails_appVersion] = appVersion;
    details[kPOSTKey_deviceDetails_appBuild] = buildNumber;
    details[kPOSTKey_deviceDetails_connectionType] = connectionType;
    
    return details;
}

@end
