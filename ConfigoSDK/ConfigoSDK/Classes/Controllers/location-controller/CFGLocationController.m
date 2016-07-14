//
//  CFGLocationController.m
//  ConfigoSDK
//
//  Created by Natan Abramov on 14/07/2016.
//  Copyright © 2016 Configo. All rights reserved.
//

#import "CFGLocationController.h"
#import <CoreLocation/CoreLocation.h>
#import "NNLogger.h"

@interface CFGLocationController () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL failed;
@end

@implementation CFGLocationController

- (instancetype)init {
    if(self = [super init]) {
        self.failed = NO;
        [self requestLocation];
    }
    return self;
}

- (void)requestLocation {
    if(!self.failed || !self.location) {
        [self.locationManager requestLocation];
    }
}

- (CLLocationManager *)locationManager {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if(!_locationManager && status != kCLAuthorizationStatusDenied && status != kCLAuthorizationStatusRestricted && status != kCLAuthorizationStatusNotDetermined) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (NSDictionary *)getLocationDictionary {
    NSMutableDictionary *retval = nil;
    if(!self.failed) {
        CLLocation *location = [self.locationManager location];
        if(location || self.location) {
            CLLocation *locationToUse = location ?: self.location;
            retval = [NSMutableDictionary dictionary];
            retval[@"latitude"] = @(locationToUse.coordinate.latitude);
            retval[@"longitude"] = @(locationToUse.coordinate.longitude);
            NNLogDebug(@"Location available", nil);
        } else {
            //For next time
            [self requestLocation];
            NNLogDebug(@"No location available", nil);
        }
    }
    return retval ? [retval copy] : nil;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    self.location = locations.count > 0 ? locations[0] : nil;
    [manager stopUpdatingLocation];
    self.failed = NO;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    self.failed = YES;
}

@end
