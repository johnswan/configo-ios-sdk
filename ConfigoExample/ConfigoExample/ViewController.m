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
                                                      [self clear: nil];
                                                  }];
    
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo: self.view animated: YES];
    hud.labelText =  NSLocalizedString(@"greet.text", @"Hello World!");
    [hud hide: YES afterDelay: 3];    
}

- (IBAction)pullConfig:(id)sender {
    [[Configo sharedConfigo] pullConfig];
}
- (IBAction)changeParams:(id)sender {
    [[Configo sharedConfigo] setCustomUserId: @"nat123"];
}

- (IBAction)drill:(id)sender {
    id value = [[Configo sharedConfigo] configValueForKeyPath: _drillField.text];
    [_configView setText: value ? [NSString stringWithFormat: @"(%@): \n%@", NSStringFromClass([value class]), value] : @"Value not found"];
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
