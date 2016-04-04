//
//  ViewController.m
//  LeumiDemo
//
//  Created by Natan Abramov on 03/04/2016.
//  Copyright © 2016 Turrisio. All rights reserved.
//

#import "LDBLoginViewController.h"
#import <ConfigoSDK/ConfigoSDK.h>

@interface LDBLoginViewController ()
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;

@end

@implementation LDBLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self updateStateText];
    _welcomeLabel.text = nil;
    [self setupConfigoCallback];
}

- (void)setupConfigoCallback {
    [[Configo sharedInstance] setCallback: ^(NSError *error, NSDictionary *rawConfig, NSArray *featuresList) {
        [self updateStateText];
        _welcomeLabel.text = [[Configo sharedInstance] configValueForKeyPath: @"welcomeString" fallbackValue: @"Simple Welcome!"];
    }];
}

- (void)updateStateText {
    NSString *stateText = nil;
    CFGConfigLoadState state = [[Configo sharedInstance] state];
    switch(state) {
        case CFGConfigNotAvailable:
            stateText = @"Config Not Available";
            break;
        case CFGConfigLoadingInProgress:
            stateText = @"Config is loading";
            break;
        case CFGConfigLoadedFromStorage:
            stateText = @"Config is loaded from storage";
            break;
        case CFGConfigLoadedFromServer:
            stateText = @"Config is loaded from server";
            break;
        case CFGConfigFailedLoadingFromServer:
            stateText = @"Config failed loading from server";
            break;
        default:
            break;
    }
    _topLabel.text = stateText;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
