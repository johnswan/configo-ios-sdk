//
//  FetchControllerTests.m
//
//
//  Created by Natan Abramov on 1/18/16.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Foundation/Foundation.h>

#import "CFGConfigController.h"
#import "CFGFileController.h"
@class CFGNetworkController;

#import "CFGResponseFactory.h"
#import "CFGResponse.h"
#import "CFGConfig.h"

@interface CFGConfigControllerTests : XCTestCase
@property (nonatomic, strong) CFGConfigController *configController;
@property (nonatomic, strong) CFGNetworkController *mockNetController;
@property (nonatomic, strong) CFGFileController *fileController;
@end

@implementation CFGConfigControllerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _mockNetController = OCMClassMock([CFGNetworkController class]);
    _fileController = OCMClassMock([CFGFileController class]);
    _configController = [[CFGConfigController alloc] initWithNetworkController: _mockNetController withFileController: _fileController];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _configController = nil;
    [super tearDown];
}

#pragma mark - Simple Response Tests

- (void)testSuccessResponse {
    [self setupRequestConfigTestWithInvocationBlock: ^(CFGConfigLoadCallback callback) {
        [self invokeConfigLoadCallbackWithSuccess: callback];
    } withTestCode: ^{
        [_configController fetchConfig: ^(CFGResponse *response, NSError *error) {
            NSLog(@"Asserting success response");
            XCTAssertNotNil(response);
            XCTAssertNil(error);
        }];
    }];
}

- (void)testEmptyResponse {
    [self setupRequestConfigTestWithInvocationBlock: ^(CFGConfigLoadCallback callback) {
        [self invokeConfigLoadCallbackWithEmptyResponse: callback];
    } withTestCode: ^{
        [_configController fetchConfig: ^(CFGResponse *response, NSError *error) {
            NSLog(@"Asserting empty response callback");
            XCTAssertNil(response);
            XCTAssertNotNil(error);
            XCTAssertTrue([error.domain containsString: @"badResponse"]);
        }];
    }];
}

#pragma mark - Test Dynamic Refresh

- (void)testNotDynamicRefreshValuesNotCalled {
    [self setupNetworkWithSuccessResponse: _mockNetController withOptionalBlock: nil];

    [_configController fetchConfig];
    CFGResponse *initialResponse = _configController.response;
    XCTAssertNotNil(initialResponse);
    NSLog(@"Initial Response is: %@", initialResponse);
    
    [_configController fetchConfig: ^(CFGResponse *response, NSError *error) {
        NSLog(@"New Response: %@", response);
        XCTAssertNotNil(response);
        XCTAssertEqualObjects(initialResponse, response, @"Should not be equal!");
    }];
}

- (void)testDynamicRefreshValueCalled {
    [self setupNetworkWithSuccessResponse: _mockNetController withOptionalBlock: nil];

    _configController.dynamicallyRefreshValues = YES;
    [_configController fetchConfig];
    CFGResponse *initialResponse = _configController.response;
    NSLog(@"Initial Response %@", initialResponse);
    XCTAssertNotNil(initialResponse);
    
    [_configController fetchConfig];
    CFGResponse *newResponse = _configController.response;
    NSLog(@"New Response %@", newResponse);
    XCTAssertNotNil(newResponse);
    XCTAssertNotEqual(initialResponse, newResponse);
}

- (void)testSavingConfig {
    [self setupNetworkWithSuccessResponse: _mockNetController withOptionalBlock: nil];
    
    OCMExpect([_fileController saveResponse: [OCMArg any] error: [OCMArg anyObjectRef]]).andReturn(YES);
    [_configController fetchConfig];
    OCMVerify([_fileController saveResponse: [OCMArg any] error: [OCMArg anyObjectRef]]);
}

#pragma mark - Presets

- (void)setupNetworkWithSuccessResponse:(CFGNetworkController *)netController withOptionalBlock:(void(^)(NSInvocation *))block {
    [self setupNetworkStubForConfig: netController withBlock: ^(NSInvocation *invocation) {
        CFGConfigLoadCallback callback = [self callbackFromNetworkControllerInvocation: invocation];
        [self invokeConfigLoadCallbackWithSuccess: callback];
        
        if(block) {
            block(invocation);
        }
    }];
}

- (void)setupNetworkWithEmptyResponse:(CFGNetworkController *)netController withOptionalBlock:(void(^)(NSInvocation *))block {
    [self setupNetworkStubForConfig: netController withBlock: ^(NSInvocation *invocation) {
        CFGConfigLoadCallback callback = [self callbackFromNetworkControllerInvocation: invocation];
        [self invokeConfigLoadCallbackWithEmptyResponse: callback];
        
        if(block) {
            block(invocation);
        }
    }];
}

#pragma mark - Helpers

- (CFGConfigLoadCallback)callbackFromNetworkControllerInvocation:(NSInvocation *)invocation {
    CFGConfigLoadCallback callback;
    [invocation getArgument: &callback atIndex: 3];
    return callback;
}

- (void)setupNetworkStubForConfig:(CFGNetworkController *)netController withBlock:(void(^)(NSInvocation *invocation))block {
    OCMStub([netController requestConfigWithConfigoData: [OCMArg any] callback: [OCMArg any]]).andDo(block);
}

- (void)setupRequestConfigTestWithInvocationBlock:(void(^)(CFGConfigLoadCallback callback))invocationCode withTestCode:(void(^)(void))testCode {
    OCMExpect([_mockNetController requestConfigWithConfigoData: [OCMArg any]
                                                      callback: [OCMArg any]]).andDo(^(NSInvocation *invocation) {
        NSLog(@"Mocking Network");
        CFGConfigLoadCallback callback = [self callbackFromNetworkControllerInvocation: invocation];
        invocationCode(callback);
    });
    
    NSLog(@"Testing Code");
    testCode();
    
    NSLog(@"Verifying Mock Called");
    OCMVerify([_mockNetController requestConfigWithConfigoData: [OCMArg any] callback: [OCMArg any]]);
}

#pragma mark - Response Data

- (void)invokeConfigLoadCallbackWithSuccess:(CFGConfigLoadCallback)callback {
    CFGResponse *response = [CFGResponseFactory staticSuccessResponse];
    callback(response, nil);
}

- (void)invokeConfigLoadCallbackWithEmptyResponse:(CFGConfigLoadCallback)callback {
    NSError *err = [NSError errorWithDomain: @"io.configo.badResponse" code: 40 userInfo: nil];
    callback(nil, err);
}

@end
