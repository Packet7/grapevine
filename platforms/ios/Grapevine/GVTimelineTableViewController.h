//
//  GVTimelineTableViewController.h
//  Grapevine
//
//  Created by Packet7, LLC. on 7/26/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DAContextMenuTableViewController.h"
#import "REComposeViewController.h"

#import "GVMessageTextView.h"

@interface GVTimelineTableViewController
    : DAContextMenuTableViewController <
        GVMessageTextViewDelegate, REComposeViewControllerDelegate,
        UIActionSheetDelegate, UISearchBarDelegate, UITextViewDelegate
    >

typedef enum
{
    GVViewControllerTypeFeed,
    GVViewControllerTypeSearch,
} GVViewControllerType;

@property (assign) GVViewControllerType viewControllerType;

- (id)initWithStyle:(UITableViewStyle)style viewControllerType:(GVViewControllerType)viewControllerType;

- (void)reset;
- (void)unsubscribe:(NSString *)aUsername;

+ (NSAttributedString *)attributedStringWithMessage:(NSString *)aMessage;

@end
