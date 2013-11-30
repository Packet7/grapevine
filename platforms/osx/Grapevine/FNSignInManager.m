/**
 * Copyright (C) 2013 Packet7, LLC.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */
 
#import "EMKeychainItem.h"

#import "NSData+Conversion.h"
#import "NSString+HMACSHA.h"

#import "FNAppDelegate.h"
#import "FNSignInManager.h"
#import "FNSetupFirstViewController.h"
#import "GVStack.h"

@interface FNSignInManager ()
@property (copy) NSString * username;
@property (copy) NSString * password;
@end

@implementation FNSignInManager

+ (FNSignInManager *)sharedInstance
{
    static FNSignInManager * gFNSignInManager = nil;
    
    if (!gFNSignInManager)
    {
        gFNSignInManager = [FNSignInManager new];
    }
    
    return gFNSignInManager;
}

- (id)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didSignInNotification:)
            name:kGVDidSignInNotification object:nil
        ];
    }
    return self;
}

- (void)signInWithUsername:(NSString *)aUsername password:(NSString *)aPassword;
{
    self.username = aUsername;
    
    self.password = aPassword;
    
    if (self.username.length > 0 && self.password.length > 0)
    {
        [[GVStack sharedInstance] signIn:self.username password:self.password];
    }
    else
    {
        NSBeep();
    }
}

#pragma mark -

- (void)didSignInNotification:(NSNotification *)aNotification
{
    NSDictionary * dict  = aNotification.object;
    
    if ([[dict objectForKey:@"status"] intValue] == 0)
    {  
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

        [delegate.window orderFrontRegardless];
        [delegate.window makeKeyWindow];
    }
    else
    {
        NSBeep();
    }
}

@end
