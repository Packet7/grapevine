//
//  GVAlert.m
//  Grapevine
//
//  Created by Packet7, LLC. on 8/29/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "GVAlert.h"

NSString * kGVDidReviewTOS02 = @"gvDidReviewTOS2";

@interface GVAlert ()
@property (strong) UIAlertView * tosAlertView;
@end

@implementation GVAlert

+ (GVAlert *)sharedInstance
{
    static GVAlert * gGVAlert = nil;
    
    if (!gGVAlert)
    {
        gGVAlert = [GVAlert new];
    }
    
    return gGVAlert;
}

- (void)showWithTOS
{
    NSString * message = NSLocalizedString(
        @"1. I am at least 17 years of age.\n\n"
        @"2. I will not publish any pornographic or other inappropriate content to the network.\n\n"
        @"3. I will not store any profane/foul languages or other inappropriate content in my user profile.\n\n"
        @"4. I will report any inappropriate content.\n\n"
        @"5. I have reviewed the Grapevine Terms Of Service and understand that any violation of any of these terms will result in immediate deletion of my Grapevine account.\n\n", nil
    );
    
    self.tosAlertView = [[UIAlertView alloc] initWithTitle:
        NSLocalizedString(@"Terms Of Service", nil) message:message
        delegate:self cancelButtonTitle:NSLocalizedString(@"Review", nil)
        otherButtonTitles:NSLocalizedString(@"Accept", nil), nil
    ];
    
    [self.tosAlertView show];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.tosAlertView)
    {
        switch (buttonIndex)
        {
            case 0:
            {
                [[UIApplication sharedApplication] openURL:
                    [NSURL URLWithString:@"http://grapevine.am/legal/tos/"]
                ];
                
                [self performSelector:@selector(showWithTOS) withObject:nil
                    afterDelay:0.25f
                ];
            }
            break;
            case 1:
            {
                [[NSUserDefaults standardUserDefaults] setObject:
                    [NSNumber numberWithBool:YES] forKey:kGVDidReviewTOS02
                ];
                
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            break;
            default:
            break;
        }
        
        self.tosAlertView = nil;
    }
}

- (void)showWithFileSizeTooLarge
{
    NSString * message = NSLocalizedString(
        @"The file size is too large.", nil
    );
    
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:
        NSLocalizedString(@"Opps!", nil) message:message
        delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil)
        otherButtonTitles:nil, nil
    ];
    
    [alertView show];
}

@end
