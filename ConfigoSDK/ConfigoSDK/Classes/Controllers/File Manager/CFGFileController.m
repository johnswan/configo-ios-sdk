//
//  CFGFileManager.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 25/08/15.
//  Copyright (c) 2015 Configo. All rights reserved.
//

#import "CFGFileController.h"
#import "CFGConfigoData.h"
#import "CFGResponse.h"
#import "CFGConstants.h"

#import "NNUtilities.h"
#import "NNJSONUtilities.h"
#import "NNSecurity.h"
#import "NNJSONObject.h"

@interface CFGFileController ()
@property (nonatomic, copy) NSString *devKey;
@property (nonatomic, copy) NSString *appId;
@end

@implementation CFGFileController

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static id _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });
    return _shared;
}

- (instancetype)initWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    NSParameterAssert(devKey);
    NSParameterAssert(appId);
    if(self = [super init]) {
        self.devKey = devKey;
        self.appId = appId;
    }
    return self;
}

- (instancetype)init {
    if(self = [super init]) {
    }
    return self;
}

#pragma mark - Configo Response

- (BOOL)saveResponse:(CFGResponse *)response error:(NSError **)err {
    return [self saveResponse: response withDevKey: _devKey withAppId: _appId error: err];
}

- (CFGResponse *)readResponse:(NSError **)err {
    return [self loadLastResponseForDevKey: _devKey appId: _appId error: err];
}

- (BOOL)saveResponse:(CFGResponse *)response withDevKey:(NSString *)devKey withAppId:(NSString *)appId error:(NSError **)err{
    BOOL success = NO;
    NSString *filePath = [self filePathWithDevKey: devKey appId: appId suffix: @"configoResponse"];
    NSString *key = [self cryptoKeyWithDevKey: devKey appId: appId];
    success = [self saveAndEncryptObject: response withKey: key toFile: filePath error: err];
    return success;
}

- (CFGResponse *)loadLastResponseForDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err {
    CFGResponse *retval = nil;
    NSString *filePath = [self filePathWithDevKey: devKey appId: appId suffix: @"configoResponse"];
    NSString *key = [self cryptoKeyWithDevKey: devKey appId: appId];
    NSDictionary *json = [self loadAndDecryptDataFromFile: filePath withKey: key error: err];
    retval = [[CFGResponse alloc] initWithDictionary: json];
    return retval;
}

#pragma mark - Configo Data

- (BOOL)saveConfigoData:(CFGConfigoData *)configoData error:(NSError **)err {
    return [self saveConfigoData: configoData withDevKey: _devKey appId: _appId error: err];
}

- (CFGConfigoData *)readConfigoData:(NSError **)err {
    return [self loadConfigoDataForDevKey: _devKey appId: _appId error: err];
}

- (CFGConfigoData *)loadConfigoDataForDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err {
    CFGConfigoData *retval = nil;
    NSString *filePath = [self filePathWithDevKey: devKey appId: appId suffix: @"configoData"];
    NSString *key = [self cryptoKeyWithDevKey: devKey appId: appId];
    NSDictionary *json = [self loadAndDecryptDataFromFile: filePath withKey: key error: err];
    retval = [[CFGConfigoData alloc] initWithDictionary: json];
    return retval;
}

- (BOOL)saveConfigoData:(CFGConfigoData *)configoData withDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err {
    BOOL success = NO;
    NSString *filePath = [self filePathWithDevKey: devKey appId: appId suffix: @"configoData"];
    NSString *key = [self cryptoKeyWithDevKey: devKey appId: appId];
    success = [self saveAndEncryptObject: configoData withKey: key toFile: filePath error: err];
    return success;
}

#pragma mark - Generic Data Saving & Loading

- (BOOL)saveAndEncryptObject:(id)object withKey:(NSString *)key toFile:(NSString *)filePath error:(NSError **)err {
    if(!object || !filePath) {
        return NO;
    }
    
    BOOL success = NO;
    NSData *data = nil;
    if([object isKindOfClass: [NSData class]]) {
        data = object;
    }
    else if([object isKindOfClass: [NNJSONObject class]] || [object conformsToProtocol: @protocol(NNJSONObject)]) {
        NSDictionary *json = [(NNJSONObject *)object dictionaryRepresentation];
        data = [NNJSONUtilities JSONDataFromObject: json error: err];
    }
    else if([object isKindOfClass: [NSDictionary class]] || [object isKindOfClass: [NSArray class]]) {
        data = [NNJSONUtilities JSONDataFromObject: object error: err];
    }
    else if([object conformsToProtocol: @protocol(NSCoding)]) {
        data = [NSKeyedArchiver archivedDataWithRootObject: object];
    }
        
    if(data) {
        NSData *encrypted = [NNSecurity encryptData: data withKey: key error: err];
        if(encrypted) {
            success = [encrypted writeToFile: filePath atomically: YES];
        }
    }
    return success;
}

- (id)loadAndDecryptDataFromFile:(NSString *)filePath withKey:(NSString *)key error:(NSError **)err {
    if(!filePath) {
        return nil;
    }
    id retval = nil;
    NSData *fileData = [NSData dataWithContentsOfFile: filePath];
    if(fileData) {
        NSData *data = [NNSecurity decrypt: fileData withKey: key error: err];
        id json = [NNJSONUtilities JSONObjectFromData: data error: err];
        retval = json ? : data;
    }
    return retval;
}

#pragma mark - Helpers

- (NSString *)filePathWithDevKey:(NSString *)devKey appId:(NSString *)appId suffix:(NSString *)suffix {
    NSString *fileName = [self fileNameWithDevKey: devKey appId: appId suffix: suffix];
    NSString *filePath = [NNUtilities pathToFileInDocumentsDirectory: fileName];
    return filePath;
}

- (NSString *)fileNameWithDevKey:(NSString *)devKey appId:(NSString *)appId suffix:(NSString *)suffix {
    NSMutableString *fileName = [NSMutableString string];
    [fileName appendString: CFGFileNamePrefix];
    if(devKey) {
        [fileName appendFormat: @"-%@", devKey];
    }
    if(appId) {
        [fileName appendFormat: @"-%@", appId];
    }
    if(suffix) {
        [fileName appendFormat: @"-%@", suffix];
    }
    return fileName;
}

- (NSString *)cryptoKeyWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    NSString *cryptoKey = [devKey stringByAppendingString: appId];
    return cryptoKey;
}

@end
