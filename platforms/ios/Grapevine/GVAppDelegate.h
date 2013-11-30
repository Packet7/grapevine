//
//  GVAppDelegate.h
//  Grapevine
//
//  Created by Packet7, LLC. on 7/26/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GVTimelineTableViewController;

@interface GVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) GVTimelineTableViewController * timelineTableViewController;
@property (strong) UIPopoverController * editProfilePopoverController;

- (void)goEditProfile:(id)sender;
- (IBAction)goSearch:(id)sender;
- (IBAction)signOut:(id)sender;

@end
