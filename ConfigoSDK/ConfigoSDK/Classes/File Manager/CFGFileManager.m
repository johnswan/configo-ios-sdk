//
//  CFGFileManager.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 25/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "CFGFileManager.h"
#import "CFGConfigoData.h"
#import "CFGConstants.h"

#import <NNLibraries/NNUtilities.h>
#import <NNLibraries/NNJSONUtilities.h>

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

- (CFGConfigoData *)configoDataForDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err {
    CFGConfigoData *retval = nil;
    NSString *filePath = [self filePathWithDevKey: devKey appId: appId];
    NSData *jsonData = [NSData dataWithContentsOfFile: filePath];
    if(jsonData) {
        NSDictionary *json = [NNJSONUtilities JSONObjectFromData: jsonData error: err];
        retval = [[CFGConfigoData alloc] initWithDictionary: json];
    } else if(err) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Configuration file not found in storage"};
        *err = [NSError errorWithDomain: @"com.configo.config.load" code: CFGErrorCodeFileNotFound userInfo: userInfo];
    }
    return retval;
}

- (BOOL)saveConfigoData:(CFGConfigoData *)configoData withDevKey:(NSString *)devKey appId:(NSString *)appId error:(NSError **)err {
    BOOL success = NO;
    NSDictionary *json = [configoData dictionaryRepresentation];
    NSData *jsonData = [NNJSONUtilities JSONDataFromObject: json error: err];
    if(jsonData) {
        NSString *filePath = [self filePathWithDevKey: devKey appId: appId];
        success = [jsonData writeToFile: filePath options: NSDataWritingFileProtectionComplete error: err];
    } else if(err) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Unable to create JSON from configoData"};
        *err = [NSError errorWithDomain: @"com.configo.config.save" code: CFGErrorCodeInvalidData userInfo: userInfo];
    }
    return success;
}
             

#pragma mark - Helpers

- (NSString *)filePathWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    NSString *fileName = [self fileNameWithDevKey: devKey appId: appId];
    NSString *filePath = [NNUtilities pathToFileInDocumentsDirectory: fileName];
    return filePath;
}

- (NSString *)fileNameWithDevKey:(NSString *)devKey appId:(NSString *)appId {
    NSString *fileName = [NSString stringWithFormat: @"%@-%@-%@", CFGFileNamePrefix, devKey, appId];
    return fileName;
}

@end
