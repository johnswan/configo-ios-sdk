//
//  CFGConfigoDataController.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 26/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//
#import "CFGConfigoDataController.h"
#import "CFGConfigoData.h"
#import "CFGFileController.h"
#import "CFGConstants.h"

#import "NNLibrariesEssentials.h"
#import "UIDevice+NNAdditions.h"
#import "NNReachabilityManager.h"
#import "NSDictionary+NNAdditions.h"
#import "NSDate+NNAdditions.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

static NSString *const kPOSTKey_deviceDetails   = @"deviceDetails";
static NSString *const kPOSTKey_userContext     = @"userContext";
static NSString *const kPOSTKey_customUserId    = @"customUserId";

static NSString *const kPOSTKey_Udid                            = @"udid";
static NSString *const kPOSTKey_deviceDetails_sdkVersion        = @"sdkVersion";
static NSString *const kPOSTKey_deviceDetails_deviceName        = @"deviceName";
static NSString *const kPOSTKey_deviceDetails_carrierName       = @"carrierName";
static NSString *const kPOSTKey_deviceDetails_deviceModel       = @"deviceModel";
static NSString *const kPOSTKey_deviceDetails_os                = @"os";
static NSString *const kPOSTKey_deviceDetails_osVersion         = @"osVersion";
static NSString *const kPOSTKey_deviceDetails_deviceLanguage    = @"deviceLanguage";
static NSString *const kPOSTKey_deviceDetails_screenSize        = @"screenSize";
static NSString *const kPOSTKey_deviceDetails_bundleId          = @"bundleId";
static NSString *const kPOSTKey_deviceDetails_appName           = @"appName";
static NSString *const kPOSTKey_deviceDetails_appVersion        = @"appVersion";
static NSString *const kPOSTKey_deviceDetails_appBuild          = @"appBuildNumber";
static NSString *const kPOSTKey_deviceDetails_connectionType    = @"connectionType";
static NSString *const kPOSTKey_deviceDetails_timezone          = @"timezoneOffset";


@interface CFGConfigoDataController ()
@property (nonatomic, strong) CFGFileController *fileController;
@property (nonatomic) BOOL userContextChanged;
@property (nonatomic) BOOL customUserIdChanged;
@property (nonatomic, strong) CFGConfigoData *configoData;
@property (nonatomic, strong) NSDictionary *currentDeviceDetails;
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
        _fileController = [[CFGFileController alloc] initWithDevKey: devKey appId: appId];
        _configoData = [_fileController readConfigoData: &err];
        
        if(!_configoData || !_configoData.udid) {
            NNLogDebug(@"ConfigoData file not found or bad", err);
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
    _currentDeviceDetails = [self deviceDetails];
    NSString *udid = [UIDevice udidFromKeychain: nil];
    
    /** Added code to server side that deep compares the sent params and the ones in the databases. */
    /** This is disabled we decided not to pre-optimize */
    /*
    BOOL udidChanged = ![udid isEqualToString: _configoData.udid];
    BOOL deviceDetailsChanged = ![_currentDeviceDetails isEqualToDictionary: _configoData.deviceDetails];
    
    
    if(udidChanged || _customUserIdChanged) {
        NNLogDebug(@"UDID or CustomUserId changed, sending userContext and deviceDetails", nil);
        //If the UDID changed or the customUserId set context and details (i.e. new user)
        [dict nnSafeSetObject: _configoData.userContext forKey: kPOSTKey_userContext];
        [dict nnSafeSetObject: _currentDeviceDetails forKey: kPOSTKey_deviceDetails];
    } else if(_userContextChanged) {
        NNLogDebug(@"UserContext changed", nil);
        //If only the user context changed - we send it out
        [dict nnSafeSetObject: _configoData.userContext forKey: kPOSTKey_userContext];
    } else if(deviceDetailsChanged) {
        NNLogDebug(@"DeviceDetails changed", nil);
        //If any details changed - we send them
        [dict nnSafeSetObject: _currentDeviceDetails forKey: kPOSTKey_deviceDetails];
    }
    */
    
    //Always add data to request
    //Add UDID and CustomUserId to all requests (Identifiers)
    [dict nnSafeSetObject: _configoData.customUserId forKey: kPOSTKey_customUserId];
    dict[kPOSTKey_Udid] = udid;
    [dict nnSafeSetObject: _configoData.userContext forKey: kPOSTKey_userContext];
    [dict nnSafeSetObject: _currentDeviceDetails forKey: kPOSTKey_deviceDetails];
    return dict;
}

- (BOOL)saveConfigoDataWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    return [self saveConfigoDataWithDevKey: devKey appId: appId error: nil];
}

- (BOOL)saveConfigoDataWithDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err {
    _customUserIdChanged = NO;
    _userContextChanged = NO;
    _configoData.deviceDetails = _currentDeviceDetails;
    BOOL success = [_fileController saveConfigoData: _configoData error: err];
    NNLogDebug(success ? @"ConfigoData save success" : @"ConfigoData save failed" , err ? *err : nil);
    return success;
}

#pragma mark - Getters

- (NSString *)udid {
    return _configoData.udid;
}

- (NSDictionary *)userContext {
    return _configoData.userContext;
}

- (BOOL)detailsChanged {
    _currentDeviceDetails = [self deviceDetails];
    BOOL deviceDetailsChanged = ![_currentDeviceDetails isEqualToDictionary: _configoData.deviceDetails];
    
    return deviceDetailsChanged || _customUserIdChanged || _userContextChanged;
}


#pragma mark - Setters

- (BOOL)setCustomUserId:(NSString *)customUserId {
    if(!customUserId && !_configoData.customUserId) {
        return NO;
    } else if(![_configoData.customUserId isEqualToString: customUserId]) {
        _configoData.customUserId = customUserId;
        _customUserIdChanged = YES;
        return YES;
    } else {
        return NO;
    }
}

- (void)clearUserContext {
    [_configoData clearUserContext];
}

- (BOOL)setUserContext:(NSDictionary *)userContext {
    //Test is done at caller level for now. (We want to keep it simple and not filter the NSDictionary)
    //id validContext = [NNJSONUtilities makeValidJSONObject: userContext];
    if(![NNJSONUtilities isValidJSONObject: userContext]) {
        return NO;
    }
    
    id validContext = userContext;
    
    if(!validContext && !_configoData.userContext) {
        return NO;
    } else if(![_configoData.userContext isEqualToDictionary: validContext]) {
        _configoData.userContext = validContext;
        _userContextChanged = YES;
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)setUserContextValue:(id)value forKey:(NSString *)key {
    //If the value is nil but the key is not, we remove the object for key.
    
    //If no value and no key, we do nothing.
    if(!value && !key) {
        return NO;
    } //If there's a value (not nil) but it's NOT a json type - we don't set it.
    else if(value && ![NNJSONUtilities isJSONTypeObject: value]) {
        return NO;
    }
    
    BOOL retval = NO;
    id original = [_configoData.userContext objectForKey: key];
    
    //Determining if the context changed.
    if(!original && !value) {
        //If no original value and no new value
        retval = NO;
    } else if(![original isEqual: value]) {
        //At least one - original or new value exist, but are not equal.
        //ConfigoData method handles it.
        retval = YES;
    }
    
    //Because the context might've changed before but not this time.
    if(retval) {
        [_configoData setUserContextValue: value forKey: key];
        _userContextChanged = retval;
    }
    
    return retval;
}

#pragma mark - Helpers

- (NSDictionary *)deviceDetails {
    NSMutableDictionary *details = [NSMutableDictionary dictionary];
    
    NSString *deviceName = [[UIDevice currentDevice] name];
    NSString *deviceModel = [UIDevice machineModel];
    NSString *os = @"iOS"; //[[UIDevice currentDevice] systemName]; //Return iPhone OS (legacy)
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = telephonyInfo.subscriberCellularProvider;
    NSString *carrierName = [carrier carrierName] ? : @"NA"; //Not always available, e.g. iPad
    
    NSString *language = @"en";
    NSArray *preferredLanguages = [NSLocale preferredLanguages];
    if(preferredLanguages.count > 0) {
        NSString *firstLang = preferredLanguages[0];
        if([firstLang rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"-_"]].location != NSNotFound) {
            NSDictionary *localeDict = [NSLocale componentsFromLocaleIdentifier: firstLang];
            NSString *langValue = [localeDict objectForKey: NSLocaleLanguageCode];
            if(langValue) {
                language = langValue;
            }
        }
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
    
    NSInteger secondsFromGMT = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSInteger hoursFromGMT = [NSDate hoursFromSeconds: secondsFromGMT];
    NSNumber *timezoneOffset = [NSNumber numberWithInteger: hoursFromGMT];
    
    details[kPOSTKey_deviceDetails_sdkVersion] = ConfigoSDKVersion;
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
    details[kPOSTKey_deviceDetails_timezone] = timezoneOffset;
    
    return details;
}

@end
