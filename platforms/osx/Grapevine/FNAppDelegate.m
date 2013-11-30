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

#import "DPSetupWindow.h"
#import "EMKeychainItem.h"

#import "INAppStoreWindow.h"

#import "NSColor+CGColor.h"
#import "NSImage+RoundCorner.h"

#import <QuartzCore/QuartzCore.h>

#import "FNAppDelegate.h"
#import "FNAvatarCache.h"
#import "FNEditProfileWindowController.h"
#import "FNMessageController.h"
#import "FNNewWindowController.h"
#import "FNProfileCache.h"
#import "FNProfileViewController.h"
#import "FNSearchViewController.h"
#import "FNSetupFirstViewController.h"
#import "FNSideBarTableCellView.h"
#import "FNSidebarTableRowView.h"
#import "FNSignInManager.h"
#import "FNSubscriptionsWindowController.h"
#import "FNToolbarMenuViewController.h"
#import "GVStack.h"
#import "GVPreferencesWindowController.h"

NSString * kGVDidDownloadMyPhotoNotification = @"gvDidDownloadMyPhotoNotification";

@interface FNAppDelegate ()
@property (strong) DPSetupWindow * setupWindow;
@property (strong) FNEditProfileWindowController * editProfileWindowController;
@property (strong) FNToolbarMenuViewController * toolbarMenuViewController;
@property (strong) GVPreferencesWindowController * preferencesWindowController;
@property (strong) NSView * currentView;
@property (strong) NSView * lastView;
@property (strong) NSMutableDictionary * downloadPhotoQueue;
@end

@implementation FNAppDelegate

int rand_int(int upper_bound)
{
    srand((unsigned int)clock());

    return rand () % upper_bound;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(didConnectNotification:)
        name:kGVDidConnectNotification object:nil
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(didDisconnectNotification:)
        name:kGVDidDisconnectNotification object:nil
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(didSignInNotification:)
        name:kGVDidSignInNotification object:nil
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(onVersionNotification:)
        name:kGVOnVersionNotification object:nil
    ];
    
    NSString * listenPort = [[NSUserDefaults standardUserDefaults]
        objectForKey:kGVPrefsListenPort
    ];
    
    if (!listenPort || listenPort.intValue < 49152)
    {
        uint16_t randomPort = rand_int(65535  - 49152 + 1) + 49152;
        
        listenPort = [NSString stringWithFormat:@"%d", randomPort];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:listenPort
        forKey:kGVPrefsListenPort
    ];
    
     NSLog(@"Listen port = %@\n", listenPort);
    
    /**
     * Start the stack.
     */
    [[GVStack sharedInstance] start:
        [NSNumber numberWithInt:listenPort.intValue]
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(didFindProfileNotification:)
        name:kGVDidFindProfileNotification object:nil
    ];
    
    self.messageController = [FNMessageController new];
    self.downloadPhotoQueue = [NSMutableDictionary dictionary];
    
    self.tableView.delegate = self.messageController;
    self.tableView.dataSource = self.messageController;
    self.messageController.tableView = self.tableView;
    self.messageController.messageControllerType = FNMessageControllerTypeFeed;
    
    if (!self.searchViewController)
    {
        self.searchViewController = [FNSearchViewController new];
        
        NSRect frame = self.contentPlaceholderView.bounds;
        
        frame.origin.x -= frame.size.width;
        
        self.searchViewController.view.frame = frame;
    }
    
    self.currentView = self.messageView;
    
    INAppStoreWindow * aWindow = (INAppStoreWindow *)[self window];

    aWindow.backgroundColor = [NSColor whiteColor];

    aWindow.hideTitleBarInFullScreen = NO;
    aWindow.centerFullScreenButton = YES;
    aWindow.titleBarHeight = 42;
    aWindow.centerTrafficLightButtons = YES;
	aWindow.trafficLightButtonsLeftMargin = 7.0;
    
//    aWindow.titleBarDrawingBlock = ^(BOOL drawsAsMainWindow, CGRect drawingRect, CGPathRef clippingPath)
//    {
//        if (([self.window styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask)
//        {
//            // ...
//        }
//        else
//        {
//            CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
//            CGContextAddPath(ctx, clippingPath);
//            CGContextClip(ctx);
//        }
//
////        [[NSColor colorWithCalibratedRed:0.96f green:0.96f blue:0.96f alpha:1.0f] set];
////        NSRectFillUsingOperation(drawingRect, NSCompositeSourceOver);
//        NSGradient *gradient = nil;
//
//        gradient = [[NSGradient alloc] initWithStartingColor:
//            [NSColor colorWithCalibratedRed:0.96f green:0.96f blue:0.96f alpha:1.0f]
//            
//            endingColor:
//            [NSColor colorWithCalibratedRed:0.95f green:0.95f blue:0.95f alpha:1.0f]
//        ];
//
//        BOOL flip = NO;
//        
//        [gradient drawInRect:drawingRect angle:flip ? 270 : 90];
//
////        [[NSColor colorWithCalibratedWhite:1.0f alpha:0.85f] setFill];
////        NSRectFill(NSMakeRect(NSMinX(drawingRect), NSMinY(drawingRect), NSWidth(drawingRect), 1));
//    };

    NSView * titleBarView = aWindow.titleBarView;
    
    // Avatar Image
    
#define AVATAR_BUTTON_SIZE 27.0f
#define AVATAR_BUTTON_PADDING 60.0f
  
   NSSize segmentSize = NSMakeSize(AVATAR_BUTTON_SIZE, AVATAR_BUTTON_SIZE);
   NSRect segmentFrame = NSMakeRect(NSMinX(titleBarView.bounds) - (segmentSize.width / 2.f) + (AVATAR_BUTTON_SIZE + AVATAR_BUTTON_PADDING), NSMidY(titleBarView.bounds) - (segmentSize.height / 2.f),
                                     segmentSize.width, segmentSize.height);
    
    NSButton * avatarbutton = [[NSButton alloc] initWithFrame:segmentFrame];

    avatarbutton.tag = 1;

    avatarbutton.image = [NSImage imageNamed:@"Menu"];
    avatarbutton.alternateImage = [NSImage imageNamed:@"MenuPressed"];
    [avatarbutton setBordered:NO];
    [avatarbutton setButtonType:NSMomentaryChangeButton];
    
    avatarbutton.target = self;
    avatarbutton.action = @selector(editProfile:);
    
    [titleBarView addSubview:avatarbutton];

    // Back Button

#define BACK_BUTTON_SIZE 27.0f
#define BACK_BUTTON_PADDING 60.0f + 60.0f
  
segmentSize = NSMakeSize(BACK_BUTTON_SIZE, BACK_BUTTON_SIZE);
segmentFrame = NSMakeRect(NSMinX(titleBarView.bounds) - (segmentSize.width / 2.f) + (BACK_BUTTON_SIZE + BACK_BUTTON_PADDING), NSMidY(titleBarView.bounds) - (segmentSize.height / 2.f),
                                     segmentSize.width, segmentSize.height);
    NSButton * backbutton = [[NSButton alloc] initWithFrame:segmentFrame];

    NSImage * srcImage = nil;
    NSImage * newImage = nil;

//    NSImage * srcImage = [[NSImage imageNamed:@"Back"] copy];
//     NSImage * newImage = [[NSImage alloc] initWithSize:[srcImage size]];
//    [newImage lockFocus];
//    [[NSColor clearColor] set];
//    NSRectFill(NSMakeRect(0,0,[newImage size].width, [newImage size].height));
//    [srcImage drawAtPoint:NSZeroPoint fromRect:
//        NSZeroRect operation:NSCompositeSourceOver fraction:0.55f
//    ];
//    [newImage unlockFocus];
    
    backbutton.tag = 1016;
    backbutton.image = [NSImage imageNamed:@"Back"];
    backbutton.alternateImage = [NSImage imageNamed:@"BackPressed"];
    [backbutton setBordered:NO];
    [backbutton setButtonType:NSMomentaryChangeButton];
    
    backbutton.target = self;
    backbutton.action = @selector(goHome:);
    backbutton.alphaValue = 0.0f;
    [backbutton setEnabled:NO];
    [titleBarView addSubview:backbutton];
    
    // Title
    
#define TITLE_WIDTH 64.0f
#define TITLE_HEIGHT 22.0f
#define TITLE_PADDING 64.0f
    segmentSize = NSMakeSize(TITLE_WIDTH, TITLE_HEIGHT);
    segmentFrame = NSMakeRect(NSMidX(titleBarView.bounds) - (segmentSize.width / 2.f) - (TITLE_WIDTH + TITLE_PADDING) / 2.0f + TITLE_PADDING, NSMidY(titleBarView.bounds) - (segmentSize.height / 2.f),
                                     segmentSize.width, segmentSize.height);
    NSTextField * titleTextField = [[NSTextField alloc] initWithFrame:segmentFrame];
    
    titleTextField.tag = 1014;
    titleTextField.stringValue = NSLocalizedString(@"Timeline", nil);
    titleTextField.font = [NSFont fontWithName:@"Droid Sans" size:14];
    [titleTextField setBordered:NO];
    [titleTextField setEditable:NO];
    [titleTextField setSelectable:NO];
    [titleTextField setDrawsBackground:NO];
    titleTextField.textColor = [NSColor darkGrayColor];
    [[titleTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];
    titleTextField.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin;
    [titleBarView addSubview:titleTextField];
    
#define SEARCH_BUTTON_SIZE 28.0f
#define SEARCH_BUTTON_PADDING 64.0f
  
   segmentSize = NSMakeSize(SEARCH_BUTTON_SIZE, SEARCH_BUTTON_SIZE);
   segmentFrame = NSMakeRect(NSMaxX(titleBarView.bounds) - (segmentSize.width / 2.f) - (SEARCH_BUTTON_SIZE + SEARCH_BUTTON_PADDING), NSMidY(titleBarView.bounds) - (segmentSize.height / 2.f),
                                     segmentSize.width, segmentSize.height);
    NSButton * searchbutton = [[NSButton alloc] initWithFrame:segmentFrame];
    
    srcImage = [[NSImage imageNamed:@"Search"] copy];
    newImage = [[NSImage alloc] initWithSize:[srcImage size]];
    [newImage lockFocus];
    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0,0,[newImage size].width, [newImage size].height));
    [srcImage drawAtPoint:NSZeroPoint fromRect:
        NSZeroRect operation:NSCompositeSourceOver fraction:0.55f
    ];
    [newImage unlockFocus];
    
    searchbutton.tag = 1015;
    searchbutton.image = newImage;
    searchbutton.alternateImage = newImage;
    [searchbutton setBordered:NO];
    [searchbutton setButtonType:NSMomentaryChangeButton];

    searchbutton.target = self;
    searchbutton.action = @selector(goSearch:);
    searchbutton.autoresizingMask = NSViewMinXMargin;
    [titleBarView addSubview:searchbutton];
    
    // Messgage Button
    
#define MESSAGE_BUTTON_SIZE 28.0f
#define MESSAGE_BUTTON_PADDING 22.0f

   segmentSize = NSMakeSize(MESSAGE_BUTTON_SIZE, MESSAGE_BUTTON_SIZE);
   segmentFrame = NSMakeRect(NSMaxX(titleBarView.bounds) - (segmentSize.width / 2.f) - (MESSAGE_BUTTON_SIZE + MESSAGE_BUTTON_PADDING), NSMidY(titleBarView.bounds) - (segmentSize.height / 2.f),
                                     segmentSize.width, segmentSize.height);
    
    NSButton * messagebutton = [[NSButton alloc] initWithFrame:segmentFrame];

//    srcImage = [[NSImage imageNamed:@"Compose"] copy];
//    newImage = [[NSImage alloc] initWithSize:[srcImage size]];
//    [newImage lockFocus];
//    [[NSColor clearColor] set];
//    NSRectFill(NSMakeRect(0,0,[newImage size].width, [newImage size].height));
//    [srcImage drawAtPoint:NSZeroPoint fromRect:
//        NSZeroRect operation:NSCompositeSourceOver fraction:0.55f
//    ];
//    [newImage unlockFocus];
    
    messagebutton.image = [NSImage imageNamed:@"Compose"];
    messagebutton.alternateImage = [NSImage imageNamed:@"ComposePressed"];
    [messagebutton setBordered:NO];
    [messagebutton setButtonType:NSMomentaryChangeButton];
    messagebutton.target = self;
    messagebutton.action = @selector(newMessage:);
    messagebutton.autoresizingMask = NSViewMinXMargin;
    
    [titleBarView addSubview:messagebutton];

    //
    
    [self.sideBarTableView selectRowIndexes:
        [NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO
    ];
    
    NSImage * defaultAvatar = [[NSImage imageNamed:@"Avatar"] copy];
    
    defaultAvatar = [defaultAvatar resize:NSMakeSize(512, 512)];

    defaultAvatar = [defaultAvatar roundCornersImageCornerRadius:512 / 2.0f];
    
    [[FNAvatarCache sharedInstance] setObject:defaultAvatar forKey:@"default"];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{    
    [self.messageController.messages removeAllObjects];
    [self.messageController.tableView reloadData];
    
    [self.window orderOut:nil];
    
    /**
     * Sign out of the stack.
     */
    [[GVStack sharedInstance] signOut];
#if 0
    /**
     * Stop the stack.
     */
    [[GVStack sharedInstance] stop];
#endif
}

- (IBAction)newMessage:(id)sender
{
    if (!self.fnNewWindowController)
    {
        self.fnNewWindowController = [FNNewWindowController new];
    }
    
    Class popoverClass = NSClassFromString(@"NSPopover");
    
    if (popoverClass)
    {
        id popover = [[popoverClass alloc] init];
        
        [popover setDelegate:self];
        
        [popover setBehavior:NSPopoverBehaviorSemitransient];
        
        [popover setContentViewController:self.fnNewWindowController.viewController];
        
        self.fnNewWindowController.popover = popover;
        
        [popover showRelativeToRect:[sender bounds] ofView:sender
            preferredEdge:NSMaxYEdge
        ];
    }
    else
    {
        [self.fnNewWindowController showWindow:nil];
        
        [self.fnNewWindowController.window makeKeyAndOrderFront:nil];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
   if (1)
   {
        NSBeginAlertSheet(
            NSLocalizedString(@"Are you sure you want to quit?", nil),
            NSLocalizedString(@"Quit", nil), NSLocalizedString(@"Cancel", nil),
            nil, [NSApp mainWindow], self,
            @selector(sheetDidEnd:returnCode:contextInfo:), nil, @"quit",
            NSLocalizedString(@"Staying online greatly benefits the network.", nil)
        );
       
       return NSTerminateLater;
   }

    return NSTerminateNow;
}


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode
       contextInfo:(void *)contextInfo
{
    if (contextInfo == @"quit")
    {
        if (returnCode == NSAlertDefaultReturn)
        {
            // Do stuff before quitting.
            
            [NSApp replyToApplicationShouldTerminate:YES];
        }
        else
        {
           [NSApp replyToApplicationShouldTerminate:NO];
        }
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender
    hasVisibleWindows:(BOOL)flag
{
    if (self.setupWindow != nil)
    {
        return NO;
    }
    else if ([GVStack sharedInstance].username == nil)
    {
        return NO;
    }
    else
    {
        [self.window makeKeyAndOrderFront:self];
    }
    
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.tag == 2001 || menuItem.tag == 2002)
    {
        return self.setupWindow == nil;
    }
    
    return YES;
}

- (IBAction)refresh:(id)sender
{
    [[GVStack sharedInstance] refresh];
}

- (IBAction)updateProfile:(id)sender
{
    [[GVStack sharedInstance] updateProfile];
    
    [self performSelector:@selector(downloadProfilePhoto)];
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 3;
}

- (NSView *)tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    FNSideBarTableCellView * result = [tableView
        makeViewWithIdentifier:@"SidebarCellView" owner:nil
    ];
    
    if (row == 0)
    {
        NSString * username = [[NSUserDefaults standardUserDefaults]
            objectForKey:@"username"
        ];
        
        NSMutableDictionary * preferences = [[[NSUserDefaults
            standardUserDefaults] objectForKey:username] mutableCopy
        ];
        
        if (preferences)
        {
            NSMutableDictionary * profile = [preferences objectForKey:@"profile"];
        
            if (profile)
            {
                NSImage * image = [[FNAvatarCache sharedInstance]
                    objectForKey:[profile objectForKey:@"p"]
                ];
                
                if (image)
                {
                    result.button.image = image;
                }
                else
                {
                    result.button.image = [[FNAvatarCache sharedInstance]
                        objectForKey:@"default"
                    ];
                }

                result.button.target = self;
                result.button.action = @selector(editProfile:);
            }
            else
            {
                result.button.image = [[FNAvatarCache sharedInstance]
                    objectForKey:@"default"
                ];
                
                result.button.target = self;
                result.button.action = @selector(editProfile:);
            }
        }
        else
        {
            result.button.image = [[FNAvatarCache sharedInstance]
                objectForKey:@"default"
            ];
        
            result.button.target = self;
            result.button.action = @selector(editProfile:);
        }
    }
    else if (row == 1)
    {
        [[result.button cell] setImageScaling:NSImageScaleNone];
        result.button.image = [NSImage imageNamed:@"Home-White-1"];
        result.button.target = self;
        result.button.action = @selector(goHome:);
#if 0
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor blackColor]];
        [shadow setShadowOffset:NSMakeSize(1.0, 1.0)];
        [shadow setShadowBlurRadius:0.5];

        [result.button setWantsLayer:YES];
        [result.button setShadow:shadow];
#endif
    }
    else if (row == 2)
    {
        [[result.button cell] setImageScaling:NSImageScaleNone];
        result.button.image = [NSImage imageNamed:@"Search-1"];
        result.button.target = self;
        result.button.action = @selector(goSearch:);
    }

    return result;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    return rowIndex > 0;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row 
{
    if (tableView == self.sideBarTableView)
    {
        FNSidebarTableRowView * view = [[FNSidebarTableRowView alloc]
            initWithFrame:NSZeroRect
        ];

        return view;
    }
    
    return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if (tableView == self.sideBarTableView)
    {
        if (row == 0)
        {
            return 64.0f;
        }
        
        return 48.0f;
    }
    
    return tableView.rowHeight;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSUInteger rowIndex = [self.sideBarTableView selectedRow];
    
    FNSideBarTableCellView * view1 = [self.sideBarTableView
        viewAtColumn:0 row:1 makeIfNecessary:NO
    ];
    
    FNSideBarTableCellView * view2 = [self.sideBarTableView
        viewAtColumn:0 row:2 makeIfNecessary:NO
    ];
    
    if (rowIndex == 1)
    {
        view1.button.image = [NSImage imageNamed:@"Home-White-1"];
        view2.button.image = [NSImage imageNamed:@"Search-1"];
        
        [self goHome:nil];
    }
    else if (rowIndex == 2)
    {
        view1.button.image = [NSImage imageNamed:@"Home-1"];
        view2.button.image = [NSImage imageNamed:@"Search-White-1"];
        
        [self goSearch:nil];
    }
}

#pragma mark -

- (IBAction)showSignInWindow:(id)sender
{
    NSViewController * firstViewController = [[FNSetupFirstViewController alloc]
        initWithNibName:@"SetupFirstViewController" bundle:[NSBundle mainBundle]
    ];
    
    self.setupWindow = [[DPSetupWindow alloc] initWithViewControllers:@[
        firstViewController] completionHandler:^(BOOL completed)
    {
        if (completed)
        {
            NSLog(@"Completed setup process");
        }
        else
        {
            NSLog(@"Cancelled setup process");
            
            [NSApp terminate:nil];
        }
        [self.setupWindow orderOut:self];
        
        self.setupWindow = 0;
    }];
    [self.setupWindow setBackgroundImage:[NSApp applicationIconImage]];
    
    // Make NSStatusWindowLevel
    [self.setupWindow setLevel:NSStatusWindowLevel];
    
    // Center sign in window.

    [self.setupWindow center];
    
    // Show sign in window
    [self.setupWindow makeKeyAndOrderFront:nil];
}

- (IBAction)preferences:(id)sender
{
    if (!self.preferencesWindowController)
    {
        self.preferencesWindowController = [GVPreferencesWindowController new];
    }
    
    [self.preferencesWindowController.window makeKeyAndOrderFront:nil];
}

- (IBAction)signOut:(id)sender
{
    [self.messageController.messages removeAllObjects];
    [self.messageController performSelector:@selector(resetGroups)];
    [self.messageController.tableView reloadData];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
    
    [self.window orderOut:nil];
    
    /**
     * Sign out of the stack.
     */
    [[GVStack sharedInstance] signOut];
    
    [self performSelector:@selector(showSignInWindow:) withObject:nil];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)goHome:(id)sender
{
    BOOL found = NO;
    
    for (NSView * view in self.contentPlaceholderView.subviews)
    {
        if ([view isEqualTo:self.messageView])
        {
            found = YES;
            break;
        }
    }
    
    if (!found)
    {
        [self.contentPlaceholderView addSubview:self.messageView];
    }
    
    NSRect frame = self.contentPlaceholderView.bounds;
    
    [[NSAnimationContext currentContext] setCompletionHandler:^
    {
        [self.searchViewController.view removeFromSuperview];

//        NSRect frame = self.contentPlaceholderView.bounds;
//        
//        [NSAnimationContext beginGrouping];
//
//        [[NSAnimationContext currentContext] setDuration:0.25f];
//
//        [self.messageView.animator setFrame:frame];
//        
//        [NSAnimationContext endGrouping];
    }];
    
    frame = self.contentPlaceholderView.bounds;

    frame.origin.x += frame.size.width;
    
    [NSAnimationContext beginGrouping];

    [[NSAnimationContext currentContext] setDuration:0.25f];

    [self.searchViewController.view.animator setFrame:frame];
    
    frame = self.contentPlaceholderView.bounds;

    [self.messageView.animator setFrame:frame];
    
    [NSAnimationContext endGrouping];

    INAppStoreWindow * aWindow = (INAppStoreWindow *)[self window];
    NSView * titleBarView = aWindow.titleBarView;
    
    NSSearchField * searchField = [titleBarView viewWithTag:1013];
    NSTextField * titleField = [titleBarView viewWithTag:1014];
    NSButton * searchButton = [titleBarView viewWithTag:1015];
    
    [searchField setEnabled:NO];
    [searchField setEditable:NO];
    [searchField setSelectable:NO];
    [searchButton setEnabled:YES];
    
    [NSAnimationContext beginGrouping];

    [[NSAnimationContext currentContext] setDuration:0.25f];

    [searchField.animator setAlphaValue:0.0f];
    [titleField.animator setStringValue:NSLocalizedString(@"Timeline", nil)];
    [searchButton.animator setAlphaValue:1.0f/*0.65f*/];
    
    [NSAnimationContext endGrouping];
    
    // Start Avatar Button
    NSButton * avatarButton = [titleBarView viewWithTag:1];
    [[NSAnimationContext currentContext] setDuration:0.25f];
    [avatarButton.animator setAlphaValue:1.0f];
    frame = avatarButton.frame;
    frame.origin.x += 60.0f;
    [avatarButton.animator setFrame:frame];
    [NSAnimationContext endGrouping];
    // End Avatar Buttton
    
    // Start Back Button
    NSButton * backButton = [titleBarView viewWithTag:1016];
    [[NSAnimationContext currentContext] setDuration:0.25f];
    [backButton.animator setAlphaValue:0.0f];
    [backButton.animator setEnabled:NO];
    frame = backButton.frame;
    frame.origin.x += 60.0f;
    [backButton.animator setFrame:frame];
    [NSAnimationContext endGrouping];
    // End Back Buttton
    
    // Start Search Button
    //NSButton * SearchButton = [titleBarView viewWithTag:1016];
    [[NSAnimationContext currentContext] setDuration:0.25f];
    [searchButton.animator setAlphaValue:1.0f];
    frame = searchButton.frame;
    frame.origin.x += 60.0f;
    [searchButton.animator setFrame:frame];
    [NSAnimationContext endGrouping];
    // End Search Buttton
}

- (IBAction)goSearch:(id)sender
{
    INAppStoreWindow * aWindow = (INAppStoreWindow *)[self window];
    NSView * titleBarView = aWindow.titleBarView;
    
    NSSearchField * searchField = [titleBarView viewWithTag:1013];
    NSTextField * titleField = [titleBarView viewWithTag:1014];
    NSButton * searchButton = [titleBarView viewWithTag:1015];
    
    if (searchButton.alphaValue < 1.0f)
    {
        return;
    }
    
    BOOL found = NO;
    
    for (NSView * view in self.contentPlaceholderView.subviews)
    {
        if ([view isEqualTo:self.searchViewController.view])
        {
            found = YES;
            break;
        }
    }
    
    if (!found)
    {
        [self.contentPlaceholderView addSubview:self.searchViewController.view];
    }
    
    [[NSAnimationContext currentContext] setCompletionHandler:^
    {
        [self.messageView removeFromSuperview];
        
//        NSRect frame = self.contentPlaceholderView.bounds;
//        
//        [NSAnimationContext beginGrouping];
//
//        [[NSAnimationContext currentContext] setDuration:0.25f];
//
//        [self.searchViewController.view.animator setFrame:frame];
//        
//        [NSAnimationContext endGrouping];
    }];

    NSRect frame = self.contentPlaceholderView.bounds;

    frame.origin.x += frame.size.width;

    [self.searchViewController.view setFrame:frame];
    
    frame = self.contentPlaceholderView.bounds;
    frame.origin.x -= frame.size.width;
    
    [NSAnimationContext beginGrouping];

    [[NSAnimationContext currentContext] setDuration:0.25f];

    [self.messageView.animator setFrame:frame];
    
    frame = self.contentPlaceholderView.bounds;

    [self.searchViewController.view.animator setFrame:frame];
    
    [NSAnimationContext endGrouping];
    
    [searchField setEnabled:YES];
    [searchField setEditable:YES];
    [searchField setSelectable:YES];
    [searchButton setEnabled:NO];
    
    [NSAnimationContext beginGrouping];

    [[NSAnimationContext currentContext] setDuration:0.25f];

    [searchField.animator setAlphaValue:1.0f];
    [titleField.animator setStringValue:NSLocalizedString(@"Search", nil)];
    [searchButton.animator setAlphaValue:0.0f];
    
    [NSAnimationContext endGrouping];
    
    // Start Avatar Button
    NSButton * avatarButton = [titleBarView viewWithTag:1];
    [[NSAnimationContext currentContext] setDuration:0.25f];
    [avatarButton.animator setAlphaValue:0.0f];
    frame = avatarButton.frame;
    frame.origin.x -= 60.0f;
    [avatarButton.animator setFrame:frame];
    [NSAnimationContext endGrouping];
    // End Avatar Buttton
    
    // Start Back Button
    NSButton * backButton = [titleBarView viewWithTag:1016];
    [[NSAnimationContext currentContext] setDuration:0.25f];
    [backButton.animator setAlphaValue:1.0f];
    [backButton.animator setEnabled:YES];
    frame = backButton.frame;
    frame.origin.x -= 60.0f;
    [backButton.animator setFrame:frame];
    [NSAnimationContext endGrouping];
    // End Back Buttton
    
    // Start Search Button
    //NSButton * SearchButton = [titleBarView viewWithTag:1016];
    [[NSAnimationContext currentContext] setDuration:0.25f];
    [searchButton.animator setAlphaValue:0.0f];
    frame = searchButton.frame;
    frame.origin.x -= 60.0f;
    [searchButton.animator setFrame:frame];
    [NSAnimationContext endGrouping];
    // End Search Buttton
}

- (IBAction)goToolbarPopover:(id)sender
{
    if (!self.toolbarMenuViewController)
    {
        self.toolbarMenuViewController = [FNToolbarMenuViewController new];
    }

    Class popoverClass = NSClassFromString(@"NSPopover");
    
    if (popoverClass)
    {
        id popover = [[popoverClass alloc] init];
        
        [popover setDelegate:self];

        [popover setBehavior:NSPopoverBehaviorSemitransient];
        
        [popover setContentViewController:self.toolbarMenuViewController];
        
        [popover showRelativeToRect:[sender bounds] ofView:sender
            preferredEdge:NSMaxYEdge
        ];
    }
    else
    {
        // ...
    }
}

- (IBAction)timeline:(id)sender
{
    if (self.self.setupWindow != nil)
    {
        // ...
    }
    else
    {
        [self.window makeKeyAndOrderFront:self];
    }
}

- (IBAction)subscriptions:(id)sender
{
    if (!self.subscriptionsWindowController)
    {
        self.subscriptionsWindowController = [FNSubscriptionsWindowController new];
    }

    [self.subscriptionsWindowController.window makeKeyAndOrderFront:nil];

    [self.subscriptionsWindowController showWindow:nil];    
}

- (IBAction)editProfile:(id)sender
{
    if (!self.editProfileWindowController)
    {
        self.editProfileWindowController = [FNEditProfileWindowController new];
    }
    
    Class popoverClass = NSClassFromString(@"NSPopover");
    
    if (popoverClass)
    {
        id popover = [[popoverClass alloc] init];
        
        [popover setDelegate:self];
        
        [popover setBehavior:NSPopoverBehaviorSemitransient];
        
        [popover setContentViewController:
            self.editProfileWindowController.viewController
        ];
        
        self.editProfileWindowController.popover = popover;
        
        [popover showRelativeToRect:[sender bounds] ofView:sender
            preferredEdge:NSMaxYEdge
        ];
    }
    else
    {
        // ...
    }
}

#pragma mark - NSNotification's

- (void)didConnectNotification:(NSNotification *)aNotification
{
    if ([GVStack sharedInstance].username == nil)
    {
        NSString * username = [[NSUserDefaults standardUserDefaults]
            objectForKey:@"username"
        ];
        
        EMGenericKeychainItem * keychainItem = [EMGenericKeychainItem
            genericKeychainItemForService:@"authService"
            withUsername:username
        ];
        
        if (username && keychainItem)
        {
            NSLog(
                @"Got password = %@ for username = %@.", [keychainItem password],
                username
            );
            
            [[FNSignInManager sharedInstance] signInWithUsername:username
                password:[keychainItem password]
            ];
        }
        else
        {    
            // Sign in window.
            
            [self performSelector:@selector(showSignInWindow:) withObject:nil];
        }
    }
}

- (void)didDisconnectNotification:(NSNotification *)aNotification
{
    // ...
}

- (void)didSignInNotification:(NSNotification *)aNotification
{
    [self.window makeKeyAndOrderFront:self];
}

- (void)didFindProfileNotification:(NSNotification *)aNotification
{
#if 1
    NSDictionary * dict = aNotification.object;

    NSString * u = [dict objectForKey:@"u"];

    NSString * username = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"username"
    ];
    
    if (u && [u isEqualToString:username])
    {
        NSMutableDictionary * preferences = [[[NSUserDefaults
            standardUserDefaults] objectForKey:username] mutableCopy
        ];
        
        NSMutableDictionary * profile = [[preferences
            objectForKey:@"profile"] mutableCopy
        ];
        
        NSDate * expires1 = [dict objectForKey:@"__t"];
        NSDate * expires2 = [profile objectForKey:@"__t"];

        NSTimeInterval lifetime1 = [[NSDate date]
            timeIntervalSinceDate:expires1
        ];
        
        NSTimeInterval lifetime2 = [[NSDate date]
            timeIntervalSinceDate:expires2
        ];
 
        //NSLog(@"%@: t1 = %.2f, t2 = %.2f", u, lifetime1, lifetime2);
        
        if (!expires2 || lifetime1 < lifetime2/*!profile || profile.count == 0*/)
        {
            profile = [NSMutableDictionary new];

            [profile addEntriesFromDictionary:dict];
            
            [preferences setObject:profile forKey:@"profile"];
            
            [[NSUserDefaults standardUserDefaults] setObject:preferences
                forKey:username
            ];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[FNProfileCache sharedInstance] setProfile:profile
                username:username
            ];
        }
        
        NSImage * image = [[FNAvatarCache sharedInstance]
            objectForKey:[profile objectForKey:@"p"]
        ];
        
        if (!image)
        {
            [self performSelector:@selector(downloadProfilePhoto)];
        }
    }
#endif
}


- (void)onVersionNotification:(NSNotification *)aNotification
{
    NSDictionary * dict = aNotification.object;

    BOOL upgrade = [[dict objectForKey:@"upgrade"] boolValue];
    
    if (upgrade)
    {
        BOOL required = [[dict objectForKey:@"required"] boolValue];
        
        if (required)
        {
            NSAlert * alert = [[NSAlert alloc] init];

            alert.informativeText = NSLocalizedString(
                @"A required update is available.", nil
            );
            alert.messageText = NSLocalizedString(@"Update Required", nil);
            
            [alert runModal];
            
            [[NSWorkspace sharedWorkspace] openURL:
                [NSURL URLWithString:@"http://grapevine.am/?platform=osx"]
            ];
            
            // Exit as we may want this node off the network.
            exit(0);
        }
        else
        {
            NSAlert * alert = [[NSAlert alloc] init];

            alert.informativeText = NSLocalizedString(
                @"An update is available.", nil
            );
            alert.messageText = NSLocalizedString(@"Update", nil);
            
            [alert runModal];
            
            [[NSWorkspace sharedWorkspace] openURL:
                [NSURL URLWithString:@"http://grapevine.am/?platform=osx"]
            ];
        }
    }
}

#pragma mark -

- (void)showProfile:(NSDictionary *)aProfile username:(NSString *)aUsername sender:(id)sender
{
    if (!self.profileViewController)
    {
        self.profileViewController = [FNProfileViewController new];
    }

    Class popoverClass = NSClassFromString(@"NSPopover");
    
    if (popoverClass)
    {
        id popover = [[popoverClass alloc] init];
        
        [popover setDelegate:self];
        
        [popover setBehavior:NSPopoverBehaviorSemitransient];
        
        [popover setContentViewController:self.profileViewController];
        
        [self.profileViewController view];
        
        [self.profileViewController setup:aUsername profile:aProfile];
        
        [popover showRelativeToRect:[sender bounds] ofView:sender
            preferredEdge:NSMaxYEdge
        ];
    }
    else
    {
        // ...
    }
}

- (void)hideProfile:(id)sender
{
    [[NSAnimationContext currentContext] setTimingFunction:
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]
    ];
    
    [[NSAnimationContext currentContext] setCompletionHandler:^
    {
        [self.profileViewController.view.animator removeFromSuperview];
    }];

    NSRect frame = self.contentPlaceholderView.bounds;

    frame.origin.x -= frame.size.width;
    
    self.currentView.frame = frame;
    
    [self.contentPlaceholderView addSubview:
        self.currentView
    ];
    
    [NSAnimationContext beginGrouping];

    [[NSAnimationContext currentContext] setDuration:0.3f];

    frame.origin.x += frame.size.width * 2;
    
    [self.profileViewController.view.animator setFrame:frame];
    
    [self.profileViewController.view.animator setAlphaValue:0.0f];
    
    frame.origin.x -= frame.size.width * 2;
    
    //
    frame.origin.x += frame.size.width;
    [self.currentView.animator setFrame:frame];
    //[self.currentView.animator setAlphaValue:1.0f];
    
    [NSAnimationContext endGrouping];
}

#pragma mark -

- (void)setupSubscriptions
{
    NSString * username = [[NSUserDefaults
        standardUserDefaults] objectForKey:@"username"]
    ;
    
    NSMutableDictionary * preferences = [[[NSUserDefaults
        standardUserDefaults] objectForKey:username] mutableCopy
    ];
    
    NSDictionary * profile = [preferences objectForKey:@"profile"];
    
    if (profile)
    {
        [[FNProfileCache sharedInstance] setProfile:profile username:username];
    }
    
    NSImage * image = [[FNAvatarCache sharedInstance]
        objectForKey:[profile objectForKey:@"p"]
    ];
    
    if (!image)
    {
        [self performSelector:@selector(downloadProfilePhoto)];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[GVStack sharedInstance] subscribe:username];
    [[GVStack sharedInstance] subscribe:@"grapevine"];
}

#pragma mark -

- (void)downloadProfilePhoto
{
    NSString * username = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"username"
    ];
    
    NSDictionary * preferences = [[NSUserDefaults
        standardUserDefaults] objectForKey:username
    ];
    
    NSDictionary * profile = [preferences objectForKey:@"profile"];
    
    NSString * p = [profile objectForKey:@"p"];
    
    if ([self.downloadPhotoQueue objectForKey:p])
    {
        return;
    }
    else
    {
        if (p)
        {
            [self.downloadPhotoQueue setObject:p forKey:p];
        }
    }

    if (p && p.length)
    {
        NSURL * url = [NSURL URLWithString:p];
        NSURLRequest * request = [NSURLRequest requestWithURL:url];

        [NSURLConnection sendAsynchronousRequest:request
                queue:[NSOperationQueue mainQueue]
                completionHandler:^(NSURLResponse * response,
                    NSData * data,
                    NSError * error)
        {
            if (!error)
            {
                NSImage * image = [[NSImage alloc] initWithData:data];
                    
                if (image)
                {
                    NSImage * original = [image copy];
                    
                    image = [image resize:NSMakeSize(128, 128)];
#if 1 // round
                    image = [image roundCornersImageCornerRadius:128.0f / 2.0f];
#else
                    image = [image roundCornersImageCornerRadius:8.0f];
#endif
                    [[FNAvatarCache sharedInstance] setObject:
                        image forKey:p
                    ];
                }
            }
        }];
    }
}

@end
