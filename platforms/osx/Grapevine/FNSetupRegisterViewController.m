//
//  FNSetupFirstViewController.m
//  DPSetupWindow
//
//  Created by Dan Palmer on 05/10/2012.
//  Copyright (c) 2012 Dan Palmer. All rights reserved.
//

#import "NSString+Hashes.h"

#import "FNSetupRegisterViewController.h"
#import "FNSetupRegisteringViewController.h"

@interface FNSetupRegisterViewController ()

@property (strong) DPSetupWindow *setupWindow;

@property (assign) IBOutlet NSTextField * usernameTextField;
@property (assign) IBOutlet NSTextField * password1TextField;
@property (assign) IBOutlet NSTextField * password2TextField;

@property (strong) FNSetupRegisteringViewController * setupRegisteringViewController;
@end

@implementation FNSetupRegisterViewController

@synthesize canContinue;
@synthesize canGoBack;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
        self.canContinue = NO;
        self.canGoBack = YES;
    }
    
    return self;
}

- (void)willProgressToNextStage
{
    if (!self.setupRegisteringViewController)
    {
        self.setupRegisteringViewController = [[FNSetupRegisteringViewController alloc]
            initWithNibName:@"SetupRegisteringViewController" bundle:[NSBundle mainBundle]
        ];
        [[self setupWindow] addNextViewController:self.setupRegisteringViewController];
    }
    
    NSString * username = self.usernameTextField.stringValue;
    NSString * password = self.password1TextField.stringValue;
    
    int64_t delta = (int64_t)(1.0e9 * 0.50f);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delta),
    dispatch_get_current_queue(), ^
    {
        [self.setupRegisteringViewController
            registerWithUsername:username password:password
        ];
    });
}

- (void)didProgressToNextStage
{

}

- (void)willProgressToStage
{

}

- (void)didProgressToStage
{

}

- (void)willRevertToPreviousStage
{

}

- (void)didRevertToPreviousStage
{

}

- (void)willRevertToStage
{

}

- (void)didRevertToStage
{

}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification
{
    NSString * username = self.usernameTextField.stringValue;
    NSString * password1 = self.password1TextField.stringValue;
    NSString * password2 = self.password2TextField.stringValue;
    
    self.canContinue =
        username.length >= 5 && password1.length >= 8 &&
        [password1 isEqualToString:password2]
    ;
}

@end
