//
//  CFGNetworkControllerTests.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 14/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHPathHelpers.h>

#import "CFGNetworkController.h"
#import "CFGEventFactory.h"

@interface CFGNetworkControllerTests : XCTestCase
@property (nonatomic) CFGNetworkController *netController;
@end

@implementation CFGNetworkControllerTests

#pragma mark - Tests

- (void)testSendEventsSuccess {
    [self setupSuccessStubs];
    
    XCTestExpectation *expectation = [self expectationWithDescription: @"sendEvents callback expectation"];
    
    NSArray *randomEvents = [CFGEventFactory randomEventsArray];
    [_netController sendEvents: randomEvents withUdid: @"123" withCallback: ^(BOOL success, NSError *error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout: 2.0f handler: nil];
}

- (void)testSendEventFailed {
    [self setupFailedStubs];
    [self setupFailedTest];
}

- (void)testNetworkDown {
    [self setupNetworkFailedStubs];
    [self setupFailedTest];
}

- (void)setupFailedTest {
    XCTestExpectation *expectation = [self expectationWithDescription: @"sendEvents callback expectation"];
    NSArray *randomEvents = [CFGEventFactory randomEventsArray];
    
    [_netController sendEvents: randomEvents withUdid: @"123" withCallback: ^(BOOL success, NSError *error) {
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout: 2.0f handler: nil];
}

#pragma mark - Setup

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [self setupStubLogs];
    
    _netController = [[CFGNetworkController alloc] initWithDevKey: @"devKey" appId: @"appId"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (void)setupStubLogs {
    [OHHTTPStubs onStubActivation:^(NSURLRequest *request, id<OHHTTPStubsDescriptor> stub, OHHTTPStubsResponse *response) {
        NSLog(@"%@ stubbed by %@.", request.URL, stub.name);
    }];
}

- (void)setupSuccessStubs {
    [OHHTTPStubs stubRequestsPassingTest: ^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString: @"/events/push"];
    } withStubResponse: ^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath: OHPathForFile(@"v1-event-push-success.json",  self.class)
                                                statusCode: 200
                                                   headers: @{@"Content-Type" : @"application/json"}];
    }].name = @"Event push v1 success stub";
}

- (void)setupNetworkFailedStubs {
    [OHHTTPStubs stubRequestsPassingTest: ^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse: ^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithError: [NSError errorWithDomain: NSURLErrorDomain code: NSURLErrorNotConnectedToInternet userInfo: nil]];
    }];
}

- (void)setupFailedStubs {
    [OHHTTPStubs stubRequestsPassingTest: ^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString: @"/events/push"];
    } withStubResponse: ^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath: OHPathForFile(@"v1-event-push-failed.json",  self.class)
                                                statusCode: 200
                                                   headers: @{@"Content-Type" : @"application/json"}];
    }];
}

@end
