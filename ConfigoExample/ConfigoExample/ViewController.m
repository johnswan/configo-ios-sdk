//
//  ViewController.m
//  ConfigoExample
//
//  Created by Natan Abramov on 16/08/15.
//  Copyright (c) 2015 Turrisio. All rights reserved.
//

#import "ViewController.h"

#import <ConfigoSDK/Configo.h>
#import "MBProgressHUD.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *drillField;
@property (weak, nonatomic) IBOutlet UITextView *configView;
@property (weak, nonatomic) IBOutlet UIView *colorView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserverForName: ConfigoConfigurationLoadCompleteNotification
                                                      object: nil
                                                       queue: [NSOperationQueue mainQueue]
                                                  usingBlock: ^(NSNotification *note) {
//                                                      NSDictionary *config = [note object];
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          NSDictionary *userInfo = note.userInfo;
                                                          NSDictionary *rawConfig = userInfo[ConfigoNotificationUserInfoRawConfigKey];
                                                          NSArray *featuresList = userInfo[ConfigoNotificationUserInfoFeaturesListKey];
                                                          NSLog(@"NSNotification, got the config back!\n config:\n%@\nFeatures:\n%@", rawConfig, featuresList);
                                                          [self clear: nil];
                                                      });
                                                  }];
    
    [[Configo sharedConfigo] setCallback: ^(NSDictionary *rawConfig, NSArray *featuresList) {
        NSLog(@"Configo callback, got the config back!\n config:\n%@\nFeatures:\n%@", rawConfig, featuresList);
    }];
}

- (IBAction)pullConfig:(id)sender {
    [[Configo sharedConfigo] pullConfig: ^(NSDictionary *rawConfig, NSArray *featuresList) {
        NSLog(@"pullConfig temp callback, got the config back!\n config:\n%@\nFeatures:\n%@", rawConfig, featuresList);
    }];
}

- (IBAction)simplePullConfig:(id)sender {
    [[Configo sharedConfigo] pullConfig];
}

- (IBAction)changeParams:(id)sender {
    NSInteger random = 1 + arc4random() % 100;
    [[Configo sharedConfigo] setCustomUserId: [NSString stringWithFormat: @"Nat%li", (long)random]];
}

- (IBAction)drill:(id)sender {
    id value = [[Configo sharedConfigo] configValueForKeyPath: _drillField.text];
    [_configView setText: value ? [NSString stringWithFormat: @"(%@): \n%@", NSStringFromClass([value class]), value] : @"Value not found"];
}

- (IBAction)searchFeature:(id)sender {
    NSString *featureKey = _drillField.text;
    BOOL feature = [[Configo sharedConfigo] featureFlagForKey: featureKey];
    [_configView setText: [NSString stringWithFormat: @"%@: %@", featureKey, feature ? @"On" : @"Off"]];
}

- (IBAction)clear:(id)sender {
    _drillField.text = nil;
    [_configView setText: [NSString stringWithFormat: @"%@", [[Configo sharedConfigo] rawConfig]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
