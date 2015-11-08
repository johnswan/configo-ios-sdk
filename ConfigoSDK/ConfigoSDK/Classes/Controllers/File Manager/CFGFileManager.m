//
//  CFGFileManager.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 25/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "CFGFileManager.h"
#import "CFGConfigoData.h"
#import "CFGResponse.h"
#import "CFGConstants.h"

#import <NNLibraries/NNUtilities.h>
#import <NNLibraries/NNJSONUtilities.h>
#import <NNLibraries/NNSecurity.h>
#import <NNLibraries/NNJSONObject.h>

@implementation CFGFileManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static id _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });
    return _shared;
}

- (instancetype)init {
    if(self = [super init]) {
        
    }
    return self;
}

#pragma mark - Configo Response

- (BOOL)saveResponse:(CFGResponse *)response withDevKey:(NSString *)devKey withAppId:(NSString *)appId error:(NSError **)err{
    BOOL success = NO;
    NSString *filePath = [self filePathWithDevKey: devKey appId: appId suffix: @"configoResponse"];
    success = [self saveAndEncryptObject: response toFile: filePath error: err];
    return success;
}

- (CFGResponse *)loadLastResponseForDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err {
    CFGResponse *retval = nil;
    NSString *filePath = [self filePathWithDevKey: devKey appId: appId suffix: @"configoResponse"];
    NSDictionary *json = [self loadAndDecryptDataFromFile: filePath error: err];
    retval = [[CFGResponse alloc] initWithDictionary: json];
    return retval;
}

#pragma mark - Configo Data

- (CFGConfigoData *)loadConfigoDataForDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err {
    CFGConfigoData *retval = nil;
    NSString *filePath = [self filePathWithDevKey: devKey appId: appId suffix: @"configoData"];
    NSDictionary *json = [self loadAndDecryptDataFromFile: filePath error: err];
    retval = [[CFGConfigoData alloc] initWithDictionary: json];
    return retval;
}

- (BOOL)saveConfigoData:(CFGConfigoData *)configoData withDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err {
    BOOL success = NO;
    NSString *filePath = [self filePathWithDevKey: devKey appId: appId suffix: @"configoData"];
    success = [self saveAndEncryptObject: configoData toFile: filePath error: err];
    return success;
}

#pragma mark - Generic Data Saving & Loading

- (BOOL)saveAndEncryptObject:(id)object toFile:(NSString *)filePath error:(NSError **)err {
    if(!object || !filePath) {
        return NO;
    }
    BOOL success = NO;
    NSData *data = nil;
    if([object isKindOfClass: [NSData class]]) {
        data = object;
    } else if([object isKindOfClass: [NNJSONObject class]] || [object conformsToProtocol: @protocol(NNJSONObject)]) {
        NSDictionary *json = [(NNJSONObject *)object dictionaryRepresentation];
        data = [NNJSONUtilities JSONDataFromObject: json error: err];
    } else if([object isKindOfClass: [NSDictionary class]] || [object isKindOfClass: [NSArray class]]) {
        data = [NNJSONUtilities JSONDataFromObject: object error: err];
    } else if([object conformsToProtocol: @protocol(NSCoding)]) {
        data = [NSKeyedArchiver archivedDataWithRootObject: object];
    }
        
    if(data) {
        NSString *key = [self cryptoKeyFromKey: CFGCryptoKey];
        NSData *encrypted = [NNSecurity encryptData: data withKey: key error: err];
        if(encrypted) {
            success = [encrypted writeToFile: filePath atomically: YES];
        }
    }
    return success;
}

- (id)loadAndDecryptDataFromFile:(NSString *)filePath error:(NSError **)err {
    if(!filePath) {
        return nil;
    }
    id retval = nil;
    NSData *fileData = [NSData dataWithContentsOfFile: filePath];
    if(fileData) {
        NSString *key = [self cryptoKeyFromKey: CFGCryptoKey];
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

- (NSString *)cryptoKeyFromKey:(NSString *)key {
    NSUInteger length = key.length;
    unichar buffer[length + 1];
    [key getCharacters: buffer];
    
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

@end
