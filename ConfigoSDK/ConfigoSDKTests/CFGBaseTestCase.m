//
//  CFGBaseTestCase.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 16/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "CFGBaseTestCase.h"
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHHTTPStubsResponse.h>

@implementation CFGBaseTestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [OHHTTPStubs removeAllStubs];
}

- (void)checkAssertBlock:(void(^)())block afterDelay:(NSTimeInterval)delay {
    NSParameterAssert(block);
    NSParameterAssert(delay > 0);
    XCTestExpectation *expectation = [self expectationWithDescription: @"assert block wait"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        block();
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout: (delay + 0.5) handler: nil];
}

@end
