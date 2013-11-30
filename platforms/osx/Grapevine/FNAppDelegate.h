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

#import <Cocoa/Cocoa.h>

@class FNMessageController;
@class FNNewWindowController;
@class FNSearchViewController;
@class FNSignInWindowController;
@class FNProfileViewController;
@class FNSubscriptionsWindowController;

@interface FNAppDelegate
    : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView * contentPlaceholderView;
@property (strong) IBOutlet NSView * messageView;
@property (strong) IBOutlet NSTableView * sideBarTableView;
@property (strong) IBOutlet NSTableView * tableView;
@property (strong) FNNewWindowController * fnNewWindowController;
@property (strong) FNMessageController * messageController;
@property (strong) FNSearchViewController * searchViewController;
@property (strong) FNSignInWindowController * signInWindowController;
@property (strong) FNProfileViewController * profileViewController;
@property (strong) FNSubscriptionsWindowController * subscriptionsWindowController
;

- (IBAction)preferences:(id)sender;
- (IBAction)signOut:(id)sender;
- (IBAction)goSearch:(id)sender;
- (IBAction)goHome:(id)sender;
- (IBAction)timeline:(id)sender;
- (IBAction)subscriptions:(id)sender;
- (IBAction)newMessage:(id)sender;
- (IBAction)refresh:(id)sender;
- (IBAction)updateProfile:(id)sender;
- (void)showProfile:(NSDictionary *)aProfile username:(NSString *)aUsername sender:(id)sender;
- (void)hideProfile:(id)sender;
- (void)setupSubscriptions;

extern NSString * kGVDidDownloadMyPhotoNotification;

@end
