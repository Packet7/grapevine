//
//  FNSubscriptionsWindowController.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/19/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "FNAppDelegate.h"
#import "FNAvatarCache.h"
#import "FNMessageController.h"
#import "FNProfileCache.h"
#import "GVStack.h"
#import "FNSubscriptionsWindowController.h"

@interface FNSubscriptionsWindowController ()
@property (assign) IBOutlet NSTableView * tableView;
@property (assign) IBOutlet NSButton * minusButton;
@property (strong) NSMutableArray * keys;
@end

@implementation FNSubscriptionsWindowController

- (id)init
{
    self = [super initWithWindowNibName:
        @"SubscriptionsWindow" owner:self
    ];
    
    if (self) {
        // ...
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [[self.window standardWindowButton:NSWindowCloseButton] setTarget:self];
    
    [self performSelector:@selector(buildKeys)];
    
    [self.tableView reloadData];
}

- (void)buildKeys
{
    NSLog(@"buildKeys");
    
    self.keys = [NSMutableArray new];
    
    id subscriptions = [GVStack sharedInstance].subscriptions;
    
    for (NSString * key in subscriptions)
    {
        id value = [subscriptions objectForKey:key];
        
        if (value && [value length])
        {
            [self.keys addObject:key];
        }
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.keys.count;
}

- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString * aKey = [self.keys objectAtIndex:row];
    NSString * anObject = [[GVStack sharedInstance].subscriptions objectForKey:aKey];
 
    NSDictionary * profile = [[FNProfileCache sharedInstance] profile:aKey];
    
    if ([tableColumn.identifier isEqualToString:@"0"])
    {
        NSImage * image = [[FNAvatarCache sharedInstance] objectForKey:
            [profile objectForKey:@"p"]
        ];
        
        if (!image)
        {
            image = [[FNAvatarCache sharedInstance] objectForKey:@"default"];
        }
        
        return image;
    }
    else if ([tableColumn.identifier isEqualToString:@"1"])
    {
        return anObject;
    }
    
    return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 28.0f;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger rowIndex = [self.tableView selectedRow];
    
    self.minusButton.enabled = rowIndex > -1;
}

#pragma mark -

- (IBAction)remove:(id)sender
{
    NSInteger rowIndex = [self.tableView selectedRow];
    
    NSString * u = [self.keys objectAtIndex:rowIndex];
    
    FNAppDelegate * delegate = [NSApp delegate];
    
    [[GVStack sharedInstance] unsubscribe:u];
    
    [self.tableView beginUpdates];
    [self.tableView removeRowsAtIndexes:
        [NSIndexSet indexSetWithIndex:rowIndex] withAnimation:NSTableViewAnimationSlideLeft
    ];
    [self.tableView endUpdates];
    
    [self performSelector:@selector(buildKeys)];
    
    [delegate.messageController didUnsubscribe:u];
    
    self.minusButton.enabled = rowIndex > -1;
}

- (IBAction)_close:(id)sender
{
    FNAppDelegate * delegate = [NSApp delegate];
    
    [self.window close];
    
    delegate.subscriptionsWindowController = nil;
}

@end
