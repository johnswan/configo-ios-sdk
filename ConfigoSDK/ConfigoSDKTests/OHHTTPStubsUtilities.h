//
//  OHHTTPStubsUtilities.h
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface OHHTTPStubsUtilities : NSObject

+ (void)setupStubLogs;
/**
 *  @brief Uses OHHTTPStubs to return an error to all requests.
 *  @param error Defaults to NSURLErrorNotConnectedToInternet error.
 */
+ (id<OHHTTPStubsDescriptor>)stubFailedNetworkWithError:(NSError *)error;

/**
 *  @brief Stub a request with a url containing a string, with a response file
 *  @param str The URL string or part of it, the criteria for the stub.
 *  @param fileName The file that contains the response JSON file.
 */
+ (id<OHHTTPStubsDescriptor>)stubWithUrlPath:(NSString *)str jsonResponseFile:(NSString *)fileName;
+ (id<OHHTTPStubsDescriptor>)stubWithUrlPath:(NSString *)str jsonResponseFile:(NSString *)fileName responseDelay:(NSTimeInterval)delay;

+ (OHHTTPStubsResponse *)jsonResponseWithFileName:(NSString *)fileName;

@end
