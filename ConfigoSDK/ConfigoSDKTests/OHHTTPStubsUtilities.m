//
//  OHHTTPStubsUtilities.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 17/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "OHHTTPStubsUtilities.h"
#import <OHHTTPStubs/OHPathHelpers.h>

@implementation OHHTTPStubsUtilities

#pragma mark - Stubbing

+ (id<OHHTTPStubsDescriptor>)stubFailedNetworkWithError:(NSError *)error {
    NSError *stubError = error ?: [NSError errorWithDomain: NSURLErrorDomain code: NSURLErrorNotConnectedToInternet userInfo: nil];
    OHHTTPStubsResponse *response = [OHHTTPStubsResponse responseWithError: stubError];
    id<OHHTTPStubsDescriptor> descriptor = [self stubWithStringInUrl: @"http" withResponse: response];
    [descriptor setName: @"Failed Network Stub"];
    return  descriptor;
}

+ (id<OHHTTPStubsDescriptor>)stubWithUrlPath:(NSString *)str jsonResponseFile:(NSString *)fileName {
    OHHTTPStubsResponse *response = [self jsonResponseWithFileName: fileName];
    id<OHHTTPStubsDescriptor> descriptor = [self stubWithStringInUrl: str withResponse: response];
    [descriptor setName: [NSString stringWithFormat: @"stub with file: %@", fileName]];
    return descriptor;
}

+ (id<OHHTTPStubsDescriptor>)stubWithUrlPath:(NSString *)str jsonResponseFile:(NSString *)fileName responseDelay:(NSTimeInterval)delay {
    OHHTTPStubsResponse *response = [self jsonResponseWithFileName: fileName];
    response.responseTime = delay;
    id <OHHTTPStubsDescriptor> descriptor = [self stubWithStringInUrl: str withResponse: response];
    [descriptor setName: [NSString stringWithFormat: @"stub with file: %@, delay: %f", fileName, delay]];
    return descriptor;
}

+ (id<OHHTTPStubsDescriptor>)stubWithStringInUrl:(NSString *)str withResponse:(OHHTTPStubsResponse *)response {
    return [OHHTTPStubs stubRequestsPassingTest: ^BOOL(NSURLRequest *request) {
        return [[[request URL] absoluteString] containsString: str];
    } withStubResponse: ^OHHTTPStubsResponse *(NSURLRequest *request) {
        return response;
    }];
}

#pragma mark - Helpers

+ (void)setupStubLogs {
    [OHHTTPStubs onStubActivation:^(NSURLRequest *request, id<OHHTTPStubsDescriptor> stub) {
        NSLog(@"%@ stubbed by %@.", request.URL, stub.name);
    }];
}

+ (OHHTTPStubsResponse *)jsonResponseWithFileName:(NSString *)fileName {
    return [OHHTTPStubsResponse responseWithFileAtPath: OHPathForFile(fileName, self.class)
                                            statusCode: 200
                                               headers: @{@"Content-Type" : @"application/json"}];
}

@end
