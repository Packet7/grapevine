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

#import "GVPreferencesWindowController.h"
#import "GVStack.h"

NSString * kGVPrefsFilteredWords = @"gvPrefsFilteredWords";
NSString * kGVPrefsListenPort = @"gvPrefsListenPort";

@interface GVPreferencesWindowController ()
@property (assign) IBOutlet NSToolbar * toolbar;
@property (assign) IBOutlet NSView * generalView;
@property (assign) IBOutlet NSView * networkView;
@property (assign) IBOutlet NSWindow * filteredWordsView;
@property (assign) IBOutlet NSTableView * filteredWordsTableView;
@property (strong) NSMutableArray * filteredWords;
@property (assign) IBOutlet NSImageView * networkConnectedImageView;
@end

@implementation GVPreferencesWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"PreferencesWindow" owner:self];
    
    if (self)
    {
        self.filteredWords = [[[NSUserDefaults standardUserDefaults]
            objectForKey:kGVPrefsFilteredWords] mutableCopy
        ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didConnectNotification:)
            name:kGVDidConnectNotification object:nil
        ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didDisconnectNotification:)
            name:kGVDidDisconnectNotification object:nil
        ];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self.window center];
    
    [self switchToGeneralView:nil];
    
    self.networkConnectedImageView.image =
        [GVStack sharedInstance].isConnected ?
        [NSImage imageNamed:NSImageNameStatusAvailable] :
        [NSImage imageNamed:NSImageNameStatusUnavailable]
    ;
}

- (IBAction)switchToGeneralView:(id)sender
{
    NSView * contentView = [self.window contentView];
    
    NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:
        self.generalView, NSViewAnimationTargetKey, 
        NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil
    ];

    NSViewAnimation * animation = [[NSViewAnimation alloc] 
        initWithViewAnimations:[NSArray arrayWithObject:dict]
    ];
    
    self.generalView.frame = contentView.bounds;
    
    [self.networkView removeFromSuperview];
    
    [self.window.contentView addSubview:self.generalView];
    
    [animation startAnimation];
    
    [self.toolbar setSelectedItemIdentifier:@"general"];
}

- (IBAction)switchToNetworkView:(id)sender
{
    NSView * contentView = [self.window contentView];
    
    NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:
        self.networkView, NSViewAnimationTargetKey,
        NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil
    ];

    NSViewAnimation * animation = [[NSViewAnimation alloc] 
        initWithViewAnimations:[NSArray arrayWithObject:dict]
    ];
    
    self.networkView.frame = contentView.bounds;
    
    [self.generalView removeFromSuperview];
    
    [self.window.contentView addSubview:self.networkView];
    
    [animation startAnimation];
    
    [self.toolbar setSelectedItemIdentifier:@"network"];
}

- (IBAction)filteredWordsShow:(id)sender
{
    [NSApp beginSheet:self.filteredWordsView modalForWindow:self.window
        modalDelegate:self didEndSelector:NULL contextInfo:NULL
    ];
}

- (IBAction)filterWordsClose:(id)sender
{
    [NSApp endSheet:self.filteredWordsView];
    
    [self.filteredWordsView orderOut:nil];
}

- (IBAction)filteredWordsAdd:(id)sender
{
    [self.filteredWords insertObject:@"" atIndex:0];
    [self.filteredWordsTableView beginUpdates];
    [self.filteredWordsTableView insertRowsAtIndexes:
        [NSIndexSet indexSetWithIndex:0] withAnimation:
        NSTableViewAnimationEffectNone
    ];
    [self.filteredWordsTableView endUpdates];
    
    [self.filteredWordsTableView editColumn:0 row:0 withEvent:nil select:YES];
}

- (IBAction)filteredWordsRemove:(id)sender
{
    NSInteger rowIndex = [self.filteredWordsTableView selectedRow];
    
    if (rowIndex > -1)
    {
        [self.filteredWordsTableView beginUpdates];
        [self.filteredWordsTableView removeRowsAtIndexes:
            [NSIndexSet indexSetWithIndex:rowIndex] withAnimation:
            NSTableViewAnimationEffectFade
        ];
        [self.filteredWordsTableView endUpdates];
        
        [self.filteredWords removeObjectAtIndex:rowIndex];
        
        [[NSUserDefaults standardUserDefaults] setObject:
            self.filteredWords forKey:kGVPrefsFilteredWords
        ];
    }
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.filteredWordsTableView)
    {
        return self.filteredWords.count;
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.filteredWordsTableView)
    {
        return [self.filteredWords objectAtIndex:row];
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object
    forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.filteredWordsTableView)
    {
        if ([object length])
        {
            [self.filteredWords replaceObjectAtIndex:row withObject:object];

            [self.filteredWordsTableView reloadData];
            
            [[NSUserDefaults standardUserDefaults] setObject:
                self.filteredWords forKey:kGVPrefsFilteredWords
            ];
        }
    }
}

#pragma mark - NSNotification's

- (void)didConnectNotification:(NSNotification *)aNotification
{
    self.networkConnectedImageView.image =
        [NSImage imageNamed:NSImageNameStatusAvailable]
    ;
}

- (void)didDisconnectNotification:(NSNotification *)aNotification
{
    self.networkConnectedImageView.image =
        [NSImage imageNamed:NSImageNameStatusUnavailable]
    ;
}

@end
