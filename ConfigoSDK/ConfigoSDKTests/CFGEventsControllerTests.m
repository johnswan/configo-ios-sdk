//
//  CFGEventsControllerTests.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 14/03/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "CFGBaseTestCase.h"
#import "CFGEventsController.h"

#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>

#import "OHHTTPStubsUtilities.h"
#import "CFGEventFactory.h"
#import "CFGEvent.h"
#import "CFGConstants.h"


#pragma mark - CFGEventsController Internal Declarations for testing

@interface CFGEventsController (Testing)
- (void)sendEvents;
- (void)startSession;
- (void)endSession;
@end


@interface CFGEventsControllerTests : CFGBaseTestCase
@property (nonatomic) CFGEventsController *eventsController;
@end

@implementation CFGEventsControllerTests

const float kTimeout = 0.1f;

#pragma mark - Tests (Sessions)

- (void)testSessionGenerate {
    XCTAssertNotNil(_eventsController.sessionId);
    XCTAssertEqual(_eventsController.sessionId.length, 32);
}

- (void)testSessionStart {
    CFGEvent *firstEvent = [[_eventsController events] firstObject];
    XCTAssertEqualObjects(CFGSessionStartEventName, firstEvent.name);
}

- (void)testSessionEnd {
    [_eventsController endSession];
    CFGEvent *endEvent = [[_eventsController events] lastObject];
    XCTAssertEqualObjects(CFGSessionEndEventName, endEvent.name);
}


#pragma mark - Tests (Events with Network)

- (void)testSendEventsSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription: @"send events expectation"];
    [self stubSuccessResponse];
    [_eventsController sendEvents];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((kTimeout / 2) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertEqual([_eventsController events].count, 0);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout: kTimeout handler: nil];
}

- (void)testSendEventsFailed {
    NSArray *eventsBeforeSend = [_eventsController events];
    [self stubFailedResponse];
    [_eventsController sendEvents];
    [self checkAssertBlock: ^{
        XCTAssertEqualObjects(eventsBeforeSend, [_eventsController events]);
        XCTAssertEqual(CFGEventsStateFailed, _eventsController.state);
    } afterDelay: kTimeout];
}

- (void)testSendEventsWhenInProgress {
    __block NSInteger timesSentRequest = 0;
    [OHHTTPStubs stubRequestsPassingTest: ^BOOL(NSURLRequest *request) {
        return [[[request URL] absoluteString] containsString: [[CFGConstants eventsPushUrl] absoluteString]];
    } withStubResponse: ^OHHTTPStubsResponse *(NSURLRequest *request) {
        timesSentRequest ++;
        OHHTTPStubsResponse *response = [OHHTTPStubsUtilities jsonResponseWithFileName: @"v1-event-push-success.json"];
        response.responseTime = 10.0f;
        return response;
    }];
    
    [_eventsController sendEvents];
    [_eventsController sendEvents];
    [self checkAssertBlock: ^{
        XCTAssertEqual(1, timesSentRequest);
    } afterDelay: kTimeout];
}

- (void)testNetworkFailed {
    NSArray *eventsBeforeSend = [_eventsController events];
    [OHHTTPStubsUtilities stubFailedNetworkWithError: nil];
    [_eventsController sendEvents];
    
    [self checkAssertBlock: ^{
        XCTAssertEqualObjects(eventsBeforeSend, [_eventsController events]);
        XCTAssertEqual(CFGEventsStateFailed, _eventsController.state);
    } afterDelay: kTimeout];
}

#pragma mark - Stubs

- (void)stubSuccessResponse {
    [OHHTTPStubsUtilities stubWithUrlPath: [[CFGConstants eventsPushUrl] absoluteString] jsonResponseFile: @"v1-event-push-success.json"];
}

- (void)stubFailedResponse {
    [OHHTTPStubsUtilities stubWithUrlPath: [[CFGConstants eventsPushUrl] absoluteString] jsonResponseFile: @"v1-event-push-failed.json"];
}

- (void)addEventsToController {
    [_eventsController addEvents: [CFGEventFactory randomEventsArray]];
}

#pragma mark - Setup

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _eventsController = [[CFGEventsController alloc] initWithDevKey: @"DEV_KEY" appId: @"APP_ID" udid: @"UDID-KEY"];
    [self addEventsToController];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

@end

