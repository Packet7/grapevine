//
//  FNProfileViewController.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/16/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "FNAppDelegate.h"
#import "FNAvatarCache.h"
#import "FNMessageController.h"
#import "FNProfileViewController.h"
#import "GVStack.h"

@interface FNProfileViewController ()
@property (assign) IBOutlet NSTableView * tableView;
@property (assign) IBOutlet NSTextField * usernameTextField;
@property (assign) IBOutlet NSButton * subscribeButton;
@property (assign) IBOutlet NSView * headerView;
@property (strong) NSMutableArray * keys;
@end

@implementation FNProfileViewController

- (id)init
{
    self = [super initWithNibName:@"ProfileView" bundle:[NSBundle mainBundle]];
    
    if (self)
    {
        self.keys = [NSMutableArray new];
    }
    
    return self;
}

- (void)awakeFromNib
{
    self.tableView.backgroundColor = [NSColor clearColor];
}

- (IBAction)subscribe:(id)sender
{
    NSParameterAssert(self.avatarImageView);
    
    NSString * u = [self.profile objectForKey:@"u"];
    
    NSLog(@"Subscribing to %@.", u);
    
    if (u && u.length)
    {
        FNAppDelegate * delegate = [NSApp delegate];
        
        if ([[GVStack sharedInstance].subscriptions objectForKey:u])
        {
            [[GVStack sharedInstance] unsubscribe:u];
            
            [delegate.messageController didUnsubscribe:u];
            
            self.subscribeButton.title = NSLocalizedString(
                @"Subscribe", nil
            );
        }
        else
        {
            [[GVStack sharedInstance] subscribe:u];

            self.subscribeButton.title = NSLocalizedString(
                @"Unsubscribe", nil
            );
        }
    }
}

- (void)setup:(NSString *)aUsername profile:(NSDictionary *)aProfile
{
    NSLog(@"aProfile = %@", aProfile);
    
    self.profile = aProfile;
    
    if (aProfile.count > 0)
    {
        NSString * u = aUsername;
        NSString * p = [self.profile objectForKey:@"p"];
        
        self.usernameTextField.stringValue = [NSString
            stringWithFormat:@"@%@", u
        ];
        
        NSImage * image = [[FNAvatarCache sharedInstance] objectForKey:p];
        
        if (image)
        {
            self.avatarImageView.image = image;
        }
        else
        {
            self.avatarImageView.image = [[FNAvatarCache sharedInstance]
                objectForKey:@"default"
            ];
        }
        
        if ([[GVStack sharedInstance].subscriptions objectForKey:u])
        {
            self.subscribeButton.title = NSLocalizedString(
                @"Unsubscribe", nil
            );
        }
        else
        {
            self.subscribeButton.title = NSLocalizedString(
                @"Subscribe", nil
            );
        }
        
        [self.keys removeAllObjects];
        [self.tableView reloadData];
        
        for (NSString * key in aProfile)
        {
            if (
                [key isEqualToString:@"u"] ||
                [key isEqualToString:@"p"] ||
                [key isEqualToString:@"transaction_id"]
                )
            {
                continue;
            }

            id value = [aProfile objectForKey:key];
            
            if ([key isEqualToString:@"__v"])
            {
                if ([value boolValue])
                {
                    self.usernameTextField.stringValue = [NSString
                        stringWithFormat:@"@%@ √", u
                    ];
                }
                
                continue;
            }
            
            if (value && [value isKindOfClass:[NSString class]] && [value length])
            {
                [self.keys addObject:key];
            }
        }
    }
}

- (IBAction)hide:(id)sender
{
    FNAppDelegate * delegate = [NSApp delegate];
    
    [delegate hideProfile:nil];
}

#pragma mark -

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.keys.count;
}

- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString * aKey = [self.keys objectAtIndex:row];
    NSString * anObject = [self.profile objectForKey:aKey];
    
    if ([tableColumn.identifier isEqualToString:@"0"])
    {
        if ([aKey isEqualToString:@"b"])
        {
            return NSLocalizedString(@"Bio:", nil);
        }
        else if ([aKey isEqualToString:@"f"])
        {
            return NSLocalizedString(@"Fullname:", nil);
        }
        else if ([aKey isEqualToString:@"l"])
        {
            return NSLocalizedString(@"Location:", nil);
        }
        else
        {
            return aKey;
        }
    }
    else if ([tableColumn.identifier isEqualToString:@"1"])
    {
        return anObject;
    }
    
    return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSString * aKey = [self.keys objectAtIndex:row];
    NSString * anObject = [self.profile objectForKey:aKey];
    
    if (anObject.length > 50)
    {
        return 84.0f;
    }
    
    return 24.0f;
}

@end
