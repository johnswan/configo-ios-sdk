//
//  DemoViewController.m
//  ConfigoExample
//
//  Created by Natan Abramov on 11/29/15.
//  Copyright © 2015 Turrisio. All rights reserved.
//

#import "DemoViewController.h"
#import <ConfigoSDK/ConfigoSDK.h>

@interface DemoViewController () {
    CGFloat _originalTop;
    CGFloat _originalLeft;
}
@property (weak, nonatomic) IBOutlet UIImageView    *logoImgView;
@property (weak, nonatomic) IBOutlet UILabel        *welcomeLabel;
@property (weak, nonatomic) IBOutlet UIButton       *featureButton;
@property (weak, nonatomic) IBOutlet UIButton       *employeeFeatureBtn;
@property (weak, nonatomic) IBOutlet UIButton       *managerFeatureBtn;
@property (weak, nonatomic) IBOutlet UILabel        *animatedLabel;

@property (weak, nonatomic) IBOutlet UITextField        *usernameField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *titleSegment;
@property (weak, nonatomic) IBOutlet UIButton           *loginBtn;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftConstraint;
@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _originalTop = _topContraint.constant;
    _originalLeft = _leftConstraint.constant;
    
    _loginBtn.layer.borderWidth = 1.0f;
    _loginBtn.layer.cornerRadius = 5.0f;
    _loginBtn.layer.borderColor = _loginBtn.titleLabel.textColor.CGColor;
    
    [self registerConfigoCallback];
    [self refreshView];
}

- (void)registerConfigoCallback {
    [Configo initWithDevKey: [Configo developmentDevKey] appId: [Configo developmentAppId]];
    [[Configo sharedInstance] setDynamicallyRefreshValues: YES];
    [[Configo sharedInstance] setCallback: ^(NSError *error, NSDictionary *rawConfig, NSArray *featuresList) {
        if(error) {
            //Problem
        } else {
            [self refreshView];
        }
    }];
}


- (void)refreshView {
    NSDictionary *rgb = [[Configo sharedInstance] configValueForKeyPath: @"bgcolor"];
    self.view.backgroundColor = [self colorFromDictionary: rgb];
    
    NSString *oldString = _welcomeLabel.text;
    _welcomeLabel.text = [[Configo sharedInstance] configValueForKeyPath: @"welcomeString" fallbackValue: oldString];
    
    BOOL ceoFeature = [[Configo sharedInstance] featureFlagForKey: @"ceo.feature" fallback: NO];
    BOOL managerFeature = [[Configo sharedInstance] featureFlagForKey: @"manager.feature" fallback: NO];
    BOOL employeeFeature = [[Configo sharedInstance] featureFlagForKey: @"employee.feature" fallback: NO];
    
    _featureButton.hidden = !ceoFeature;
    _animatedLabel.hidden = !ceoFeature;
    
    _employeeFeatureBtn.hidden = !employeeFeature;
    _managerFeatureBtn.hidden = !managerFeature;
}

#pragma mark - IBActions

- (IBAction)crazyFeature:(id)sender {
    [self animateLabel];
}

- (IBAction)login:(id)sender {
    NSString *username = _usernameField.text;
    if(username.length == 0) {
        [[[UIAlertView alloc] initWithTitle: @"Username" message: @"Please input a valid username"
                                   delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
    } else {
        NSInteger segmentIndex = _titleSegment.selectedSegmentIndex;
        NSString *jobTitle = [self titleFromSegmentIndex: segmentIndex];
        [[Configo sharedInstance] setUserContextValue: jobTitle forKey: @"jobTitle"];
        [[Configo sharedInstance] setUserContextValue: username forKey: @"username"];
        [[Configo sharedInstance] pullConfig];
    }
}

#pragma mark - Helpers

- (NSString *)titleFromSegmentIndex:(NSInteger)index {
    NSString *retval = nil;
    switch(index) {
        case 0:
            retval = @"CEO";
            break;
        case 1:
            retval = @"Manager";
            break;
        case 2:
            retval = @"Employee";
            break;
        default:
            retval = @"Employee";
            break;
    }
    return retval;
}

- (void)animateLabel {
    Configo *configo = [Configo sharedInstance];
    CGFloat x = [self floatFromObj: [configo configValueForKeyPath: @"animationParams.x" fallbackValue: @200]];
//    CGFloat y = [self floatFromObj: [configo configValueForKeyPath: @"animationParams.y" fallbackValue: @300]];
    NSTimeInterval interval = [self floatFromObj: [configo configValueForKeyPath: @"animationParams.interval" fallbackValue: @2]];
    
    _leftConstraint.constant = _leftConstraint.constant == x ? _originalLeft : x;
//    _topContraint.constant = _topContraint.constant == y ? _originalTop : y;
    [UIView animateWithDuration: interval delay: 0 options: UIViewAnimationOptionBeginFromCurrentState animations: ^{
        [self.view layoutIfNeeded];
    } completion: nil];
}

- (UIColor *)colorFromDictionary:(NSDictionary *)rgb {
    NSInteger red = [self integerFromObj: rgb[@"red"]];
    NSInteger green = [self integerFromObj: rgb[@"green"]];
    NSInteger blue = [self integerFromObj: rgb[@"blue"]];
    CGFloat alpha = [self floatFromObj: rgb[@"alpha"]];
    return [UIColor colorWithRed: (red / 255.0f) green: (green / 255.0f) blue: (blue / 255.0f) alpha: alpha];
}

- (NSInteger)integerFromObj:(id)obj {
    if([obj respondsToSelector: @selector(integerValue)]) {
        return [obj integerValue];
    } else {
        return 255;
    }
}

- (CGFloat)floatFromObj:(id)obj {
    if([obj respondsToSelector: @selector(floatValue)]) {
        return [obj floatValue];
    } else {
        return 1.0f;
    }
}

@end
