//
//  Configo.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 16/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "Configo.h"
#import "CFGConstants.h"
#import "CFGResponse.h"
#import "CFGResponseHeader.h"
#import "CFGInternalError.h"

#import <NNLibraries/NNLibrariesEssentials.h>
#import <NNLibraries/NNURLConnectionManager.h>
#import <NNLibraries/NSDictionary+NNAdditions.h>
#import <NNLibraries/NSData+NNAdditions.h>
#import <NNLibraries/NNSecurity.h>
#import <NNLibraries/NNUICKeyChainStore.h>
#import <NNLibraries/NNReachabilityManager.h>
#import <NNLibraries/UIDevice+NNAdditions.h>

@import CoreTelephony;

#pragma mark - Constants

//NSNotification domains constants
NSString *const ConfigoConfigurationLoadCompleteNotification = @"com.configo.config.loadFinished";
NSString *const ConfigoConfigurationLoadErrorNotification = @"com.configo.config.loadError";
NSString *const ConfigoNotificationUserInfoErrorKey = @"configoError";

//Keychain constants
static NSString *const kKeychainKey_deviceDetails = @"deviceDetails";

//HTTP header keys constants
static NSString *const kHTTPHeaderKey_authHeader = @"x-configo-auth";
static NSString *const kHTTPHeaderKey_devKey = @"x-configo-devKey";
static NSString *const kHTTPHeaderKey_appId = @"x-configo-appId";

//HTTP POST keys constants
static NSString *const kPOSTKey_deviceDetails = @"deviceDetails";
static NSString *const kPOSTKey_userContext = @"userContext";
static NSString *const kPOSTKey_customUserId = @"customUserId";
//device details keys
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

//HTTP JSON Response key consants
static NSString *const kResponseKey_header = @"header";
static NSString *const kResponseKey_response = @"response";

#pragma mark - Private Declarations

@interface Configo ()
@property (nonatomic, copy) NSString *devKey;
@property (nonatomic, copy) NSString *appId;

@property (nonatomic, copy) NSString *customUserId;
@property (nonatomic, strong) NSMutableDictionary *userContext;
@property (nonatomic, strong) CFGResponseHeader *responseHeader;
@property (nonatomic, strong) CFGResponse *response;
@end

#pragma mark - Implementation

@implementation Configo

#pragma mark - Init

static id _shared = nil;

+ (void)initWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] initWithDevKey: devKey appId: appId];
    });
}

+ (instancetype)sharedConfigo {
    return _shared;
}

- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    if(!devKey || !appId) {
        return nil;
    }
    
    if(self = [super init]) {
        [NNReachabilityManager sharedManager];
        
        self.devKey = devKey;
        self.appId = appId;
        
        _response = [self responseFromFileWithDevKey: devKey withAppId: appId];
        if(_response) {
            _state = CFGConfigLoadedFromStorage;
        } else {
            _state = CFGConfigNotAvailable;
        }
        
        [self pullConfig];
        
        NNLogDebug(@"Configo: Init", (@{@"devKey" : devKey, @"appId" : appId}));
    }
    return self;
}

- (instancetype)init {
    return nil;
}

#pragma mark - Pull Config

- (void)pullConfig {
    [self pullBaseConfig];
}

- (void)pullBaseConfig {
    NNLogDebug(@"Loading Config: start", nil);
    _state = CFGConfigLoadingInProgress;
    
    NNURLConnectionManager *connectionMgr = [NNURLConnectionManager sharedManager];
    
    NSDictionary *headers = @{kHTTPHeaderKey_authHeader : @"natanavra",
                              kHTTPHeaderKey_devKey : _devKey,
                              kHTTPHeaderKey_appId : _appId};
    [connectionMgr setHttpHeaders: headers];
    connectionMgr.requestSerializer = [NNJSONRequestSerializer serializer];
    connectionMgr.responseSerializer = [NNJSONResponseSerializer serializer];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    BOOL fromKeychain;
    NSString *udid = [UIDevice udidFromKeychain: &fromKeychain];
    NSDictionary *deviceDetails = [self deviceDetailsIfChanged];
    
    [params nnSafeSetObject: _customUserId forKey: kPOSTKey_customUserId];
    [params nnSafeSetObject: udid forKey: kPOSTKey_Udid];
    [params nnSafeSetObject: deviceDetails forKey: kPOSTKey_deviceDetails];
    [params nnSafeSetObject: _userContext forKey: kPOSTKey_userContext];
    
    NSURL *baseConfigURL = [CFGConstants getConfigURL];
    
    NNLogDebug([@"Load Config: " stringByAppendingString: fromKeychain ? @"UDID loaded from keychain" : @"UDID generated"], udid);
    NNLogDebug(@"Loading Config: GET", (@{@"URL" : baseConfigURL, @"Headers" : headers, @"Params" : params}));
    
    [connectionMgr GET: baseConfigURL parameters: params completion: ^(NSHTTPURLResponse *response, id object, NSError *error) {
        NNLogDebug(@"LoadingConfig: HTTPResponse", response);
        NSError *retError = error;
        
        if([object isKindOfClass: [NSDictionary class]]) {
            _responseHeader = [[CFGResponseHeader alloc] initWithDictionary: object[kResponseKey_header]];
            if(_responseHeader.internalError) {
                _state = CFGConfigFailedLoading;
                NNLogDebug(@"Loading Config: Internal error", _responseHeader.internalError);
                retError = [_responseHeader.internalError error];
            } else {
                _response = [[CFGResponse alloc] initWithDictionary: object[kResponseKey_response]];
                if(_response) {
                    _state = CFGConfigLoadedFromServer;
                    [self persistResponse: _response withDevKey: _devKey withAppId: _appId];
                    [self saveDeviceDetailsToKeychain: deviceDetails];
                    NNLogDebug(@"Loading Config: Done", _response.config);
                } else {
                    _state = CFGConfigFailedLoading;
                }
            }
        }
        if(retError) {
            _state = CFGConfigFailedLoading;
            NNLogDebug(@"Loading Config: Error", retError);
            NSDictionary *userInfo = @{ConfigoNotificationUserInfoErrorKey : retError};
            [[NSNotificationCenter defaultCenter] postNotificationName: ConfigoConfigurationLoadErrorNotification object: self userInfo: userInfo];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName: ConfigoConfigurationLoadCompleteNotification object: self userInfo: [self config]];
        }
    }];
}

#pragma mark - Setters

- (void)setCustomUserId:(NSString *)userId {
    [self setCustomUserId: userId userContext: nil];
}

- (void)setCustomUserId:(NSString *)userId userContext:(NSDictionary *)context {
    [self setCustomUserId: userId userContext: context error: nil];
}

- (void)setCustomUserId:(NSString *)userId userContext:(NSDictionary *)context error:(NSError *)err {
    _customUserId = [userId copy];
    id validContext = [NNJSONUtilities makeValidJSONObject: context];
    self.userContext = validContext;
}

- (void)setUserContextValue:(id)value forKey:(NSString *)key {
    id validValue = [NNJSONUtilities makeValidJSONObject: value];
    
    if(validValue) {
        if(!_userContext) {
            _userContext = [NSMutableDictionary dictionary];
        }
        
        [_userContext setValue: value forKey: key];
    }
}

#pragma mark - Getters

- (NSDictionary *)config {
    return _response.config;
}

- (id)configForKeyPath:(NSString *)keyPath {
    if(keyPath.length == 0) {
        return nil;
    }
    
    NSDictionary *config = _response.config;
    NSArray *dotComps = [keyPath componentsSeparatedByString: @"."];
    id jumper = config;
    for(NSString *key in dotComps) {
        //Allow a user to pass a key corresponding to array without an index, only if the array has one item inside.
        if([jumper isKindOfClass: [NSArray class]]) {
            NSArray *array = (NSArray *)jumper;
            if(array.count == 1) {
                jumper = array[0];
            }
        }
        
        //If we're not in a dictionary and we're still drilling down - exit the loop, the key is irrelevant.
        if(![jumper isKindOfClass: [NSDictionary class]]) {
            jumper = nil;
            break;
        }
        
        //Search for bracket in the key (to support arrays)
        NSRange openBracketRange = [key rangeOfString: @"["];
        if(openBracketRange.location != NSNotFound) {
            NSString *clearKey = [key substringToIndex: openBracketRange.location];
            jumper = [jumper objectForKey: clearKey];
            //Will be set to 'YES' only if we found a closing bracket and there was a valid numeric value inside.
            BOOL valid = NO;
            
            if([jumper isKindOfClass: [NSArray class]]) {
                NSRange closeBracketRange = [key rangeOfString: @"]"];
                if(closeBracketRange.location != NSNotFound) {
                    NSRange inBracketRange = NSMakeRange(openBracketRange.location, closeBracketRange.location - openBracketRange.location);
                    NSString *inBracketString = [key substringWithRange: inBracketRange];
                    NSCharacterSet *numbersSet = [NSCharacterSet decimalDigitCharacterSet];
                    NSString *clearValue = [inBracketString stringByTrimmingCharactersInSet: [numbersSet invertedSet]];
                    if(clearValue.length > 0) {
                        NSInteger bracketValue = [clearValue integerValue];
                        NSArray *array = (NSArray *)jumper;
                        if(bracketValue >= 0 && bracketValue < array.count) {
                            valid = YES;
                            jumper = array[bracketValue];
                        }
                    }
                }
            }
            
            if(!valid) {
                jumper = nil;
            }
        } else {
            jumper = [jumper objectForKey: key];
        }
        
        if(jumper == nil) {
            break;
        }
    }
    return jumper;
}

#pragma mark - File Storage

- (NSString *)fileNameWithDevKey:(NSString *)devKey withAppId:(NSString *)appId {
    NSString *fileName = [NSString stringWithFormat: @"%@-%@-%@", CFGFileNamePrefix, devKey, appId];
    return fileName;
}

- (BOOL)persistResponse:(CFGResponse *)response withDevKey:(NSString *)devKey withAppId:(NSString *)appId {
    NSString *cryptoKey = CFGCryptoKey;
    NSDictionary *json = [response jsonRepresentation];
    BOOL success = NO;
    if(json) {
        NSError *parseError = nil;
        NSData *jsonData = [NNJSONUtilities JSONDataFromObject: json error: &parseError];
        if(jsonData) {
            NSError *cryptoError = nil;
            NSData *encrypted = [NNSecurity encryptData: jsonData withKey: cryptoKey error: &cryptoError];
            if(encrypted) {
                NSString *fileName = [self fileNameWithDevKey: devKey withAppId: appId];
                NSString *filePath = [NNUtilities pathToFileInDocumentsDirectory: fileName];
                success = [encrypted writeToFile: filePath atomically: YES];
                if(success) {
                    NNLogDebug(@"Save Config to File: saved config data to file", filePath);
                } else {
                    NNLogDebug(@"Save Config to File: failed to save config data to file", nil);
                }
            } else {
                NNLogDebug(@"Save Config to File: failed to encrypt config JSON data", cryptoError);
            }
        } else {
            NNLogDebug(@"Save Config to File: failed to create config JSON data", parseError);
        }
    }
    return success;
}

- (CFGResponse *)responseFromFileWithDevKey:(NSString *)devKey withAppId:(NSString *)appId {
    NSString *fileName = [self fileNameWithDevKey: devKey withAppId: appId];
    NSString *filePath = [NNUtilities pathToFileInDocumentsDirectory: fileName];
    NSData *encryptedData = [NSData dataWithContentsOfFile: filePath];
    if(encryptedData) {
        NSError *cryptoError = nil;
        NSData *unencrypted = [NNSecurity decrypt: encryptedData withKey: CFGCryptoKey error: &cryptoError];
        if(unencrypted) {
            NSError *parseError = nil;
            NSDictionary *json = [NNJSONUtilities JSONObjectFromData: unencrypted error: &parseError];
            if(json) {
                return [[CFGResponse alloc] initWithDictionary: json];
            } else {
                NNLogDebug(@"Config Load From File: failed to parse JSON data", parseError);
            }
        } else {
            NNLogDebug(@"Config Load From File: failed to decrypt JSON data", cryptoError);
        }
    } else {
        NNLogDebug(@"Config Load From File: failed to read data from file", nil);
    }
    return nil;
}

#pragma mark - Helpers

- (NSDictionary *)validUserContext:(id)context {
    NSMutableDictionary *validContext = [NSMutableDictionary dictionary];
    [context enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
        if([obj isKindOfClass: [NSDictionary class]]) {
            
        } else if([obj isKindOfClass: [NSArray class]]) {
            
        } else if([obj isKindOfClass: [NSString class]]) {
            
        }
    }];
    return validContext;
}

- (NSString *)cryptoKeyFromKey:(NSString *)key {
    NSUInteger length = key.length;
    unichar buffer[length + 1];
    for(NSUInteger i = 0 ; i < length ; i ++) {
        unichar current = buffer[i];
        if(current == 'A') {
            buffer[i] = 'B';
        } else if(current == 'B') {
            buffer[i] = 'C';
        } else if(current == '1') {
            buffer[i] = '3';
        }
    }
    return [NSString stringWithCharacters: buffer length: length];
}

- (NSDictionary *)deviceDetailsIfChanged {
    BOOL changed = YES;
    NSData *savedDeviceDetailsData = [NNUICKeyChainStore dataForKey: kKeychainKey_deviceDetails];
    NSDictionary *deviceDetails = [self reserved_deviceDetails];
    if(savedDeviceDetailsData) {
        NSError *jsonError = nil;
        NSDictionary *savedDetails = [NNJSONUtilities JSONObjectFromData: savedDeviceDetailsData error: &jsonError];
        if(savedDetails) {
            //Compare saved details and current details
            BOOL equal = [savedDetails isEqualToDictionary: deviceDetails];
            changed = !equal;
            NNLogDebug(changed ? @"Device Details: changed" : @"Device Details: No change", nil);
        } else {
            NNLogDebug(@"Device Details: failed to load from keychain", jsonError);
        }
    } else {
        NNLogDebug(@"Device Details: no details in keychain", nil);
    }
    
    return changed ? deviceDetails : nil;
}

- (void)saveDeviceDetailsToKeychain:(NSDictionary *)deviceDetails {
    if(!deviceDetails) {
        return;
    }
    NSError *jsonError = nil;
    NSData *deviceDetailsJSON = [NNJSONUtilities JSONDataFromObject: deviceDetails error: &jsonError];
    if(deviceDetailsJSON) {
        BOOL success = [NNUICKeyChainStore setData: deviceDetailsJSON forKey: kKeychainKey_deviceDetails];
        NSString *log = [NSString stringWithFormat: @"Device Details: %@", success ? @"saved to keychain" : @"failed saving to keychain"];
        NNLogDebug(log, nil);
    } else {
        NNLogDebug(@"Device Details: failed creating JSON data", jsonError);
    }
}

- (NSDictionary *)reserved_deviceDetails {
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
    NSArray *preferredLanguages = [[NSBundle mainBundle] preferredLocalizations];
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
