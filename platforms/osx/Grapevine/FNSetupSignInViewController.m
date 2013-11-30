//
//  FNSetupFirstViewController.m
//  DPSetupWindow
//
//  Created by Dan Palmer on 05/10/2012.
//  Copyright (c) 2012 Dan Palmer. All rights reserved.
//

#import "FNSetupSignInViewController.h"
#import "FNSetupSigningInViewController.h"

@interface FNSetupSignInViewController ()

@property (strong) DPSetupWindow * setupWindow;
@property (assign) IBOutlet NSTextField * usernameTextField;
@property (assign) IBOutlet NSSecureTextField * passwordTextField;
@property (retain) FNSetupSigningInViewController * setupSigningInViewController;
@end

@implementation FNSetupSignInViewController

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

- (void)awakeFromNib
{
    NSString * username = [[NSUserDefaults
        standardUserDefaults] objectForKey:@"username"
    ];

    if (username)
    {
        self.usernameTextField.stringValue = username;
    }
}

- (void)willProgressToNextStage
{
    NSLog(@"sign in");
    
    if (!self.setupSigningInViewController)
    {
        self.setupSigningInViewController = [[FNSetupSigningInViewController alloc]
            initWithNibName:@"SetupSigningInViewController" bundle:[NSBundle mainBundle]
        ];
        [[self setupWindow] addNextViewController:self.setupSigningInViewController];    
    }
    
    NSString * username = self.usernameTextField.stringValue;
    NSString * password = self.passwordTextField.stringValue;
    
    int64_t delta = (int64_t)(1.0e9 * 0.50f);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delta),
    dispatch_get_current_queue(), ^
    {
        [self.setupSigningInViewController signInWithUsername:username password:password];
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
    NSString * password = self.passwordTextField.stringValue;
    
    self.canContinue = username.length >= 5 && password.length >= 8;
}

@end
