//
//  ConfigoSDKTests.m
//  ConfigoSDKTests
//
//  Created by Natan Abramov on 1/18/16.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Configo.h"
#import "ConfigoPrivate.h"

#import "CFGEventsController.h"
#import "CFGEvent.h"

#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>

@interface ConfigoSDKTests : XCTestCase
@property (nonatomic, weak) Configo *configo;
@end

@implementation ConfigoSDKTests

#pragma mark - Tests

- (void)testCallback {
    XCTestExpectation *expectaction = [self expectationWithDescription: @"callback expectation"];
    [_configo setCallback: ^(NSError *error, NSDictionary *rawConfig, NSArray *featuresList) {
        //Callback is being called when loaded from storage. (Probably what Guy was yapping about)
        NSLog(@"Callback: %@", rawConfig);
        XCTAssertNil(error);
        [expectaction fulfill];
    }];
    [self waitForExpectationsWithTimeout: 20.0 handler: nil];
}

- (void)testConfigValues {
    id value = [_configo configValueForKeyPath: @"string" fallbackValue: nil];
    XCTAssertEqualObjects(@"value", value);
    
    value = [_configo configValueForKeyPath: @"array[3].key" fallbackValue: nil];
    XCTAssertEqualObjects(@"value", value);
    
    value = [_configo configValueForKeyPath: @"dict.dict.key" fallbackValue: nil];
    XCTAssertEqualObjects(@"inner", value);
}

- (void)testEventAddition {
    NSString *expectedName = @"clickEvent";
    NSDictionary *expectedProps = @{@"prop1" : @"value"};
    [_configo trackEvent: expectedName withProperties: expectedProps];
    CFGEvent *event = [[[_configo eventsController] events] lastObject];
    NSString *name = event.name;
    NSDictionary *props = event.properties;
    XCTAssertEqualObjects(expectedName, name);
    XCTAssertEqualObjects(expectedProps, props);
}

#pragma mark - Setup

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [self setupHttpStubs];
    
    NSString *devKey = @"test";
    NSString *appId = @"test";
    
    [Configo setLoggingLevel: CFGLogLevelNone];
    [Configo initWithDevKey: devKey appId: appId];
    _configo = [Configo sharedInstance];
}

- (void)setupHttpStubs {
    [OHHTTPStubs onStubActivation:^(NSURLRequest *request, id<OHHTTPStubsDescriptor> stub) {
        NSLog(@"%@ stubbed by %@.", request.URL, stub.name);
    }];
    
    [OHHTTPStubs stubRequestsPassingTest: ^BOOL(NSURLRequest *request) {
        NSString *url = [[request URL] absoluteString];
        return [url containsString: @"v1"] && [url containsString: @"status"];
    } withStubResponse: ^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath: OHPathForFile(@"v1-status-false-success.json", self.class)
                                                statusCode: 200
                                                   headers: @{@"Content-Type" : @"application/json"}];
    }].name = @"status-v1 stub";
    
    [OHHTTPStubs stubRequestsPassingTest: ^BOOL(NSURLRequest *request) {
        NSString *url = [[request URL] absoluteString];
        return [url containsString: @"getConfig"] && [url containsString: @"v2"];
    } withStubResponse: ^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath: OHPathForFile(@"v2-getConfig-success.json", self.class)
                                                statusCode: 200
                                                   headers: @{@"Content-Type" : @"application/json"}];
    }].name = @"getConfig-v2 stub";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

@end
