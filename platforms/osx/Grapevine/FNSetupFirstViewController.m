//
//  FNSetupFirstViewController.m
//  DPSetupWindow
//
//  Created by Dan Palmer on 05/10/2012.
//  Copyright (c) 2012 Dan Palmer. All rights reserved.
//

#import "FNSetupFirstViewController.h"
#import "FNSetupRegisterViewController.h"
#import "FNSetupSignInViewController.h"

@interface FNSetupFirstViewController ()

@property (strong) DPSetupWindow *setupWindow;
@property (strong) FNSetupRegisterViewController * setupRegisterViewController;
@property (strong) FNSetupSignInViewController * setupSignInViewController;

@end

@implementation FNSetupFirstViewController

@synthesize canContinue;
@synthesize canGoBack;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
        self.canContinue = YES;
    }
    
    return self;
}

- (void)willProgressToNextStage
{
    if (self.matrix.selectedRow == 0)
    {
        [self.setupWindow removeViewController:self.setupSignInViewController];
        self.setupSignInViewController = 0;
        
        // new account
        if (!self.setupRegisterViewController)
        {
            self.setupRegisterViewController = [[
                FNSetupRegisterViewController alloc] initWithNibName:
                @"SetupRegisterViewController" bundle:[NSBundle mainBundle]
            ];
            [[self setupWindow] addNextViewController:self.setupRegisterViewController];
        }
    }
    else
    {
        [self.setupWindow removeViewController:self.setupRegisterViewController];
        self.setupRegisterViewController = 0;
        
        // have account
        if (!self.setupSignInViewController)
        {
            self.setupSignInViewController = [[
                FNSetupSignInViewController alloc] initWithNibName:
                @"SetupSignInViewController" bundle:[NSBundle mainBundle]
            ];
            [[self setupWindow] addNextViewController:self.setupSignInViewController];
        }
    }
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

@end
