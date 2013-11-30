//
//  FNSetupSigningInViewController.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/22/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "EMKeychainItem.h"

#import "NSData+Conversion.h"
#import "NSString+HMACSHA.h"

#import "FNAppDelegate.h"
#import "FNSetupSigningInViewController.h"
#import "GVStack.h"

@interface FNSetupSigningInViewController ()
@property (strong) DPSetupWindow *setupWindow;
@property (copy) NSString * username;
@property (copy) NSString * password;
@property (assign) IBOutlet NSTextField * errorTextField;
@end

@implementation FNSetupSigningInViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
         self.canContinue = NO;
        self.canGoBack = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didSignInNotification:)
            name:kGVDidSignInNotification object:nil
        ];
    }
    
    return self;
}

#pragma mark -

- (void)willProgressToNextStage
{

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

#pragma mark -

- (void)didSignInNotification:(NSNotification *)aNotification
{
    NSDictionary * dict  = aNotification.object;
    
    if ([[dict objectForKey:@"status"] intValue] == 0)
    {    
        self.canContinue = YES;
        
        self.errorTextField.stringValue = NSLocalizedString(
            @"Success!", nil
        );
        
        [self.setupWindow performSelector:@selector(next:) withObject:nil];
        
        EMGenericKeychainItem * keychainItem = [EMGenericKeychainItem
            genericKeychainItemForService:@"authService"
            withUsername:self.username
        ];

        if (keychainItem)
        {
            [keychainItem setPassword:self.password];
        }
        else
        {
            NSLog(@"genericKeychainItemForService failed");
            
            keychainItem = [EMGenericKeychainItem
                addGenericKeychainItemForService:@"authService"
                withUsername:self.username password:self.password
            ];
        
            if (!keychainItem)
            {
                NSLog(@"addGenericKeychainItemForService failed");
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:self.username
            forKey:@"username"
        ];
        
        NSMutableDictionary * preferences = [[[NSUserDefaults
            standardUserDefaults] objectForKey:self.username] mutableCopy
        ];
        
        if (!preferences)
        {
            [[NSUserDefaults standardUserDefaults] setObject:
                [NSMutableDictionary new] forKey:self.username
            ];
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        FNAppDelegate * delegate = (FNAppDelegate *)[NSApp delegate];
        
        [delegate setupSubscriptions];
        
        [delegate.window makeKeyAndOrderFront:nil];
    }
    else
    {
        NSBeep();

        self.errorTextField.stringValue = NSLocalizedString(
            @"Sign in failed, please try again.", nil
        );
    }
}

- (void)signInWithUsername:(NSString *)aUsername password:(NSString *)aPassword;
{
    self.username = aUsername;
    
    self.password = aPassword;
    
    if (self.username.length > 0 && self.password.length > 0)
    {
        self.errorTextField.stringValue = NSLocalizedString(@"Signing In...", nil);
        
        [[GVStack sharedInstance] signIn:self.username password:self.password];
    }
    else
    {
        NSBeep();
    }
}

@end
