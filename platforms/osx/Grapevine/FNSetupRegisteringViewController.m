//
//  FNSetupSigningInViewController.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/22/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "FNAppDelegate.h"
#import "FNSetupRegisteringViewController.h"
#import "GVStack.h"
#import "FNSignInManager.h"

@interface FNSetupRegisteringViewController ()
@property (strong) DPSetupWindow *setupWindow;
@property (strong) NSURLConnection * urlConnection;
@property (strong) NSMutableData * responseData;
@property (copy) NSString * username;
@property (copy) NSString * password;
@property (assign) IBOutlet NSTextField * errorTextField;
@end

@implementation FNSetupRegisteringViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
         self.canContinue = NO;
        self.canGoBack = YES;
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

- (void)registerWithUsername:(NSString *)aUsername password:(NSString *)aPassword;
{
    self.username = aUsername;
    self.password = aPassword;
    
    if (self.username.length > 0 && self.password.length > 0)
    {
        self.errorTextField.stringValue = NSLocalizedString(@"Registering...", nil);
        
        self.responseData = [NSMutableData data];
        
        NSURL * url = [NSURL URLWithString:
            [NSString stringWithFormat:@"https://grapevine.am/register?u=%@&p=%@&ss=empty",
            self.username, self.password]
        ];
        
        NSLog(@"Registering, url = %@", url);
        
        self.urlConnection = [NSURLConnection connectionWithRequest:
            [NSURLRequest requestWithURL:url] delegate:self
        ];

        [self.urlConnection start];
    }
    else
    {
        NSBeep();
    }
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection
    didFailWithError:(NSError *)error
{
    NSLog(@"error = %@", error);
    
    self.responseData = 0;
    
    self.errorTextField.stringValue = NSLocalizedString(
        @"Registration failed, please try again.", nil
    );
}

- (void)connection:(NSURLConnection *)connection
    didReceiveResponse:(NSURLResponse *)response
{
    self.responseData.length = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary * json = [NSJSONSerialization
        JSONObjectWithData:self.responseData options:0 error:nil
    ];
    
    NSString * message = [json objectForKey:@"message"];
    NSString * status = [json objectForKey:@"status"];
    
    if (status && status.intValue == 0)
    {
        self.canContinue = YES;
        
        self.errorTextField.stringValue = NSLocalizedString(
            @"Success!", nil
        );
        
        [self.setupWindow performSelector:@selector(next:) withObject:nil];

        [[FNSignInManager sharedInstance] signInWithUsername:
            self.username password:self.password
        ];
    }
    else
    {
        NSBeep();

        self.errorTextField.stringValue = [NSString stringWithFormat:
            NSLocalizedString(
            @"Registration failed (%@), please try again.", nil), message
        ];
    }
    
    self.responseData = 0;
}

- (BOOL)connection:(NSURLConnection *)connection
    canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod
        isEqualToString:NSURLAuthenticationMethodServerTrust
    ];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (
        [challenge.protectionSpace.authenticationMethod
            isEqualToString:NSURLAuthenticationMethodServerTrust]
        )
    {
        if (
            [challenge.protectionSpace.host
            rangeOfString:@"grapevine.am"].location != NSNotFound
            )
        {
            [challenge.sender useCredential:
                [NSURLCredential credentialForTrust:
                challenge.protectionSpace.serverTrust]
                forAuthenticationChallenge:challenge
            ];
        }
    }

    [challenge.sender
        continueWithoutCredentialForAuthenticationChallenge:challenge
    ];
}

@end
