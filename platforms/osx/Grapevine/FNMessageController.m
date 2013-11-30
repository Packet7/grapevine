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

#include <math.h>

#import "RegexKitLite.h"

#import "NSImage+RoundCorner.h"
#import "NSAlert+Popover.h"

#import "FNAppDelegate.h"
#import "FNAvatarCache.h"
#import "FNGroupTableCellView.h"
#import "FNImageWindowController.h"
#import "FNMessageController.h"
#import "FNMessageGroup.h"
#import "FNMessageTextView.h"
#import "FNNewWindowController.h"
#import "FNProfileCache.h"
#import "FNSearchViewController.h"
#import "FNTableCellView.h"
#import "FNSidebarTableRowView.h"
#import "GVStack.h"
#import "GVPreferencesWindowController.h"

#ifndef max
#define max(a,b) \
({ __typeof__ (a) _a = (a); \
__typeof__ (b) _b = (b); \
_a > _b ? _a : _b; })
#endif

@interface FNMessageController ()

/**
 * If set, this is a search (message) view, not a feed (message) view.
 */
@property (assign) NSInteger searchTransactionId;

@property (strong) NSTimer * expiredMessageTimer;
@property (strong) NSTimer * updateTimer;

@property (strong) NSMutableDictionary * downloadPhotoQueue;

- (NSArray *)scanStringForLinks:(NSString *)string;
- (NSArray *)scanStringForUsernames:(NSString *)string;
- (NSArray *)scanStringForHashtags:(NSString *)string;

@end

@implementation FNMessageController

- (id)init
{
    if (self = [super init])
    {
        self.searchTransactionId = -1;
        self.messages = [NSMutableArray new];
        self.downloadPhotoQueue = [NSMutableDictionary dictionary];
        
        [self resetGroups];

        [[NSNotificationCenter defaultCenter] addObserver:
            self selector:@selector(scrollViewContentBoundsDidChange:)
            name:NSViewBoundsDidChangeNotification
            object:self.tableView.window.contentView
        ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didFindMessageNotification:)
            name:kGVDidFindMessageNotification object:nil
        ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didFindProfileNotification:)
            name:kGVDidFindProfileNotification object:nil
        ];
        
        self.expiredMessageTimer = [NSTimer
            scheduledTimerWithTimeInterval:30.0f target:self
            selector:@selector(removeExpired) userInfo:nil repeats:YES
        ];
        
        self.updateTimer = [NSTimer
            scheduledTimerWithTimeInterval:10.0f target:self
            selector:@selector(updateTick) userInfo:nil repeats:YES
        ];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self.tableView setGridColor:[NSColor whiteColor]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.messages.count;
}

- (NSView *)tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSMutableDictionary * dict = [self.messages objectAtIndex:row];
    
    if ([dict objectForKey:@"isGroup"])
    {
        FNGroupTableCellView * cellView = [tableView
            makeViewWithIdentifier:@"GroupView" owner:nil
        ];
        
        NSString * title = [dict objectForKey:@"title"];
        
        cellView.textField.textColor = [NSColor colorWithCalibratedRed:
            0.57f green:0.57f blue:0.57f alpha:1.0f
        ];
        
        cellView.textField.stringValue = title;
        
        cellView.tag = row;
        
        return cellView;
    }

    FNTableCellView * result = [tableView
        makeViewWithIdentifier:@"MessageView" owner:nil
    ];
    
    @try
    {
        NSString * u = [dict objectForKey:@"u"];

        NSAttributedString * attributedMessage = [dict
            objectForKey:@"attributedMessage"
        ];
        
        result.messageTextField.delegate = self;
        [result.messageTextField setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [result.messageTextField setBackgroundColor:self.tableView.backgroundColor];
        [result.messageTextField setTextContainerInset:NSZeroSize];
        [[result.messageTextField textStorage] setAttributedString:attributedMessage];
        [result.messageTextField setEditable:NO];
        [result.messageTextField setSelectable:YES];
        //[result.messageTextField setBackgroundColor:[NSColor magentaColor]];
        
        NSDictionary * profile = [[FNProfileCache sharedInstance]
            profile:u
        ];
        
        NSImage * image = [[FNAvatarCache sharedInstance] objectForKey:
            [profile objectForKey:@"p"]
        ];
        
        if (image)
        {
            result.imageView.image = image;
        }
        else
        {
            result.imageView.image = [[FNAvatarCache sharedInstance]
                objectForKey:@"default"
            ];
        }

        NSString * f = [profile objectForKey:@"f"];
        
        if (f && f.length)
        {
            result.usernameTextField.stringValue = f;
        }
        else
        {
            result.usernameTextField.stringValue = u;
        }

        NSTimeInterval _t = [[NSDate date] timeIntervalSinceDate:
            [dict objectForKey:@"__t"]
        ];

        BOOL isSecs = NO;
        BOOL isMins = NO;
        BOOL isHours = NO;
        BOOL isExpired = NO;
        
        NSTimeInterval time = _t;
        
        if (time > 60 * 60 * 72)
        {
            isExpired = YES;
        }
        else if (time > 60 * 60)
        {
            isHours = true;
            
            time = time / 60 / 60;
        }
        else if (time > 60)
        {
            isMins = YES;
            
            time = time / 60;
        }
        else
        {
            isSecs = YES;
        }

        BOOL verified = [[dict objectForKey:@"__v"] boolValue];

        result.timestampTextField.stringValue = [NSString
            stringWithFormat:@"%.1f %@ ago via %@%@",
            max(1, time), isSecs ? @"seconds" :
            (isMins ? @"minutes" : @"hours"), ((f && f.length) ? f : u),
            verified ? @" √" : @""
        ];
        
        result.avatarButton.target = self;
        result.avatarButton.action = @selector(goProfile:);
    }
    @catch (NSException *exception)
    {
        NSLog(@"exception = %@", exception);
    }
    @finally
    {
        // ...
    }

    return result;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    CGFloat ret = 0.0f;
    
    NSDictionary * dict = [self.messages objectAtIndex:row];
    
    if ([dict objectForKey:@"isGroup"])
    {
        ret = 30.0f;
    }
    else
    {    
        NSAttributedString * attributedMessage = [dict
            objectForKey:@"attributedMessage"
        ];

        if (attributedMessage)
        {
//            NSNumber * rowHeight = [dict objectForKey:@"rowHeight"];
//            
//            if (rowHeight)
//            {
//                return rowHeight.intValue;
//            }
            
            // Consider caching height for performance.
            ret = [FNTableCellView heightForText:attributedMessage
                withWidth:self.tableView.frame.size.width - 80.0f
            ] + 42.0f;
            
//            NSMutableDictionary * dict2 = [dict mutableCopy];
//            
//            [dict2 setObject:[NSNumber numberWithInt:ret] forKey:@"rowHeight"];
//            
//            [self.messages replaceObjectAtIndex:row withObject:dict2];
        }
        else
        {
            ret = tableView.rowHeight;
        }
    }

    return ret;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    return [[self.messages objectAtIndex:row] objectForKey:@"isGroup"] != nil;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    CGRect frame = tableView.frame;
    
    frame.size.height = 0.0f;
    
    FNSidebarTableRowView * view = [[FNSidebarTableRowView alloc]
        initWithFrame:frame
    ];

    return view;
}

- (void)showActionMenu:(id)sender
{
    NSRect frame = [(NSButton *)sender frame];
    
    NSPoint menuOrigin = [[(NSButton *)sender superview]
        convertPoint:NSMakePoint(frame.origin.x, frame.origin.y +
        frame.size.height + 8.0f) toView:nil
    ];

    NSEvent * event =  [NSEvent mouseEventWithType:NSLeftMouseDown
        location:menuOrigin modifierFlags:NSLeftMouseDownMask timestamp:0
        windowNumber:[[(NSButton *)sender window] windowNumber]
        context:[[(NSButton *)sender window] graphicsContext] eventNumber:0
        clickCount:1 pressure:1
    ];
   
    NSMenu * menu = [[NSMenu alloc] init];
    
    menu.autoenablesItems = NO;
    
    NSMenuItem * republishMenuItem = [menu insertItemWithTitle:
        NSLocalizedString(@"Republish", nil) action:@selector(republish:)
        keyEquivalent:@"" atIndex:0
    ];
    
    republishMenuItem.target = self;
    republishMenuItem.representedObject = sender;

    [NSMenu popUpContextMenu:menu withEvent:event forView:(NSButton *)sender];
}

- (void)republish:(id)sender
{
    NSMenuItem * menuItem = (NSMenuItem *)sender;
    
    NSInteger rowIndex = [self.tableView rowForView:menuItem.representedObject];
    
    NSDictionary * dict = [self.messages objectAtIndex:rowIndex];
    
    NSString * m = [NSString stringWithFormat:
        @"RE @%@ %@", [dict objectForKey:@"u"], [dict objectForKey:@"m"]
    ];

    NSAlert * alert = [NSAlert alertWithMessageText:
        NSLocalizedString(@"Republish to your subscribers?", nil)
        defaultButton:NSLocalizedString(@"Republish", nil)
        alternateButton:NSLocalizedString(@"Cancel", nil) otherButton:nil
        informativeTextWithFormat:@"%@", m
    ];

    [alert runAsPopoverForView:menuItem.representedObject withCompletionBlock:^(NSInteger result)
    {
        switch (result)
        {
            case 1000:
            {
                [[GVStack sharedInstance] post:m];
                
                NSString * username = [[NSUserDefaults standardUserDefaults]
                    objectForKey:@"username"
                ];
                
                NSString * query = [NSString stringWithFormat:@"u=%@", username];
                
                [[GVStack sharedInstance] find:query];    
            }
            break;
            case 1001:
            break;
            default:
            break;
        }
    }];
}

#pragma mark NSTableViewDelegate

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
//    NSRange visibleRows = [self.tableView rowsInRect:
//        [self.tableView.window.contentView bounds]
//    ];
//    
//    for (NSInteger i = visibleRows.location; i < visibleRows.length; i++)
//    {
//        NSDictionary * dict = [self.messages objectAtIndex:i];
//        
//        NSMutableDictionary * dict2 = [dict mutableCopy];
//    
//        [dict2 removeObjectForKey:@"rowHeight"];
//    
//        [self.messages replaceObjectAtIndex:i withObject:dict2];
//    }
//
    NSRange visibleRows = NSMakeRange(0, self.messages.count - 1);/*[self.tableView rowsInRect:
        [self.tableView.window.contentView bounds]
    ];*/
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [self.tableView noteHeightOfRowsWithIndexesChanged:
        [NSIndexSet indexSetWithIndexesInRange:visibleRows]
    ];
    [NSAnimationContext endGrouping];
}

- (void)scrollViewContentBoundsDidChange:(NSNotification*)notification
{
    NSRange visibleRows = [self.tableView rowsInRect:
        [self.tableView.window.contentView bounds]
    ];
//
//    for (NSInteger i = visibleRows.location; i < visibleRows.length; i++)
//    {
//        NSDictionary * dict = [self.messages objectAtIndex:i];
//        
//        NSMutableDictionary * dict2 = [dict mutableCopy];
//    
//        [dict2 removeObjectForKey:@"rowHeight"];
//    
//        [self.messages replaceObjectAtIndex:i withObject:dict2];
//    }

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [self.tableView noteHeightOfRowsWithIndexesChanged:
        [NSIndexSet indexSetWithIndexesInRange:visibleRows]
    ];
    [NSAnimationContext endGrouping];
}

#pragma mark -

- (void)didFindMessageNotification:(NSNotification *)aNotification
{    
    NSMutableDictionary * dict = [aNotification.object mutableCopy];
    
    //NSLog(@"didFindMessageNotification = %@", dict);
    
    NSString * u1 = [dict objectForKey:@"u"];
    NSString * m1 = [dict objectForKey:@"m"];
    
#define ENABLE_CONTENT_FILTER 1
#if (defined ENABLE_CONTENT_FILTER && ENABLE_CONTENT_FILTER)
    NSArray * filteredWords = [[NSUserDefaults standardUserDefaults]
        objectForKey:kGVPrefsFilteredWords
    ];
    
    if (filteredWords && filteredWords.count)
    {
        for (NSString * filteredWord in filteredWords)
        {
            if (
                [m1 rangeOfString:filteredWord options:NSCaseInsensitiveSearch
                ].location != NSNotFound
                )
            {
                return;
            }
        }
    }
#endif // ENABLE_CONTENT_FILTER

    // Trim trailing whitespace
    NSRange range = [m1 rangeOfString:@"\\s*$" options:NSRegularExpressionSearch];
    m1 = [m1 stringByReplacingCharactersInRange:range withString:@""];
    [dict setObject:m1 forKey:@"m"];
    
    NSInteger transactionId = [[dict objectForKey:@"transaction_id"] intValue];

    if (self.messageControllerType == FNMessageControllerTypeSearch)
    {
        if (self.searchTransactionId == transactionId)
        {
            /**
             * If we do not have a profile for this user perform
             * a lookup on it.
             */
            NSDictionary * profile = [[FNProfileCache sharedInstance]
                profile:u1
            ];
    
            if (!profile || profile.count == 0)
            {
                NSString * query = [NSString
                    stringWithFormat:@"u=%@", u1
                ];
                
                [[GVStack sharedInstance] find:query];
            }
        }
        else
        /**
         * Make sure the transaction id belongs to this controller.
         */
        {
            return;
        }
    }
    else if (self.messageControllerType == FNMessageControllerTypeFeed)
    {
        FNAppDelegate * delegate = (FNAppDelegate *)[NSApp delegate];
        
        /**
         * Make sure they are in our subscriptions.
         */
        if (![[GVStack sharedInstance].subscriptions objectForKey:u1])
        {
            return;
        }
    }

    if (u1.length && m1.length)
    {
        NSInteger rowIndex = 0;
        
        for (NSDictionary * dict2 in self.messages)
        {
            NSString * u2 = [dict2 objectForKey:@"u"];
            NSString * m2 = [dict2 objectForKey:@"m"];
            
            if ([u1 isEqualToString:u2] && [m1 isEqualToString:m2])
            {
                [self.tableView reloadDataForRowIndexes:
                    [NSIndexSet indexSetWithIndex:rowIndex]
                    columnIndexes:[NSIndexSet indexSetWithIndex:0]
                ];
                
                return;
            }
            
            rowIndex++;
        }
        
        // Building up our attributed string
        NSMutableAttributedString * attributedStatusString = [[
            NSMutableAttributedString alloc] initWithString:m1
        ];
        
        // Defining our paragraph style for the tweet text. Starting with the shadow to make the text
        // appear inset against the gray background.
        NSShadow * textShadow = [[NSShadow alloc] init];
        [textShadow setShadowColor:[NSColor colorWithDeviceWhite:1 alpha:.8]];
        [textShadow setShadowBlurRadius:0];
        [textShadow setShadowOffset:NSMakeSize(0, -1)];
                                 
        NSMutableParagraphStyle * paragraphStyle = [[NSParagraphStyle
            defaultParagraphStyle] mutableCopy
        ];
        [paragraphStyle setMinimumLineHeight:22];
        [paragraphStyle setMaximumLineHeight:22];
        [paragraphStyle setParagraphSpacing:0];
        [paragraphStyle setParagraphSpacingBefore:0];
        [paragraphStyle setTighteningFactorForTruncation:4];
        [paragraphStyle setAlignment:NSNaturalTextAlignment];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];

        // Our initial set of attributes that are applied to the full string length
        NSDictionary *fullAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSColor colorWithDeviceHue:.53 saturation:.13 brightness:.26 alpha:1], NSForegroundColorAttributeName,
                                        textShadow, NSShadowAttributeName,
                                        [NSCursor arrowCursor], NSCursorAttributeName,
                                        [NSNumber numberWithFloat:0.0], NSKernAttributeName,
                                        [NSNumber numberWithInt:0], NSLigatureAttributeName,
                                        paragraphStyle, NSParagraphStyleAttributeName,
                                        [NSFont fontWithName:@"Droid Sans" size:14], NSFontAttributeName, nil];
        [attributedStatusString addAttributes:fullAttributes range:NSMakeRange(0, [m1 length])];
            
        // Generate arrays of our interesting items. Links, usernames, hashtags.
        NSArray *linkMatches = [self scanStringForLinks:m1];
        NSArray *usernameMatches = [self scanStringForUsernames:m1];
        NSArray *hashtagMatches = [self scanStringForHashtags:m1];
        
        // Iterate across the string matches from our regular expressions, find the range
        // of each match, add new attributes to that range	
        for (NSString *linkMatchedString in linkMatches) {
            NSRange range = [m1 rangeOfString:linkMatchedString];
            if( range.location != NSNotFound ) {
                // Add custom attribute of LinkMatch to indicate where our URLs are found. Could be blue
                // or any other color.
                NSDictionary *linkAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [NSCursor pointingHandCursor], NSCursorAttributeName,
                                          [NSColor grayColor], NSForegroundColorAttributeName,
                                          [NSFont fontWithName:@"Droid Sans" size:14], NSFontAttributeName,
                                          linkMatchedString, @"LinkMatch",
                                          nil];
                [attributedStatusString addAttributes:linkAttr range:range];
            }
        }
        
        for (NSString *usernameMatchedString in usernameMatches) {
            NSRange range = [m1 rangeOfString:usernameMatchedString];
            if( range.location != NSNotFound ) {
                // Add custom attribute of UsernameMatch to indicate where our usernames are found
                NSDictionary *linkAttr2 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           [NSColor darkGrayColor], NSForegroundColorAttributeName,
                                           [NSCursor pointingHandCursor], NSCursorAttributeName,
                                           [NSFont fontWithName:@"Droid Sans" size:14], NSFontAttributeName,
                                           usernameMatchedString, @"UsernameMatch",
                                           nil];
                [attributedStatusString addAttributes:linkAttr2 range:range];
            }
        }
        
        for (NSString *hashtagMatchedString in hashtagMatches) {
            NSRange range = [m1 rangeOfString:hashtagMatchedString];
            if( range.location != NSNotFound ) {
                // Add custom attribute of HashtagMatch to indicate where our hashtags are found
                NSDictionary *linkAttr3 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [NSColor grayColor], NSForegroundColorAttributeName,
                                          [NSCursor pointingHandCursor], NSCursorAttributeName,
                                          [NSFont fontWithName:@"Droid Sans" size:14], NSFontAttributeName,
                                          hashtagMatchedString, @"HashtagMatch",
                                          nil];
                [attributedStatusString addAttributes:linkAttr3 range:range];
            }
        }
        
        [dict setObject:attributedStatusString forKey:@"attributedMessage"];
        
        [self deliverNotificationIfMentionedMe:dict];
        
        @synchronized(self.messages)
        {
            [self.messages addObject:dict];
            
            [self.messages sortUsingDescriptors:[NSArray arrayWithObject:
                [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
            ];
            
            NSInteger index = [self.messages indexOfObject:dict];
            
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:0.5f];
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexes:
                [NSIndexSet indexSetWithIndex:index]
                withAnimation:NSTableViewAnimationSlideDown
            ];
            [self.tableView endUpdates];
            //[self.tableView scrollRowToVisible:index];
            [NSAnimationContext endGrouping];
            
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:0];
            [self.tableView beginUpdates];
            [self.tableView noteHeightOfRowsWithIndexesChanged:
                [NSIndexSet indexSetWithIndexesInRange:
                NSMakeRange(0, self.messages.count - 1)]
            ];
            [self.tableView endUpdates];
            [NSAnimationContext endGrouping];
        }
        
        if (self.messageControllerType == FNMessageControllerTypeFeed)
        {
            Class NSUserNotification = NSClassFromString(@"NSUserNotification");
            
            if (NSUserNotification)
            {
                id notification = [[NSUserNotification alloc] init];
                [notification setTitle:[NSString stringWithFormat:@"@%@", u1]];
                [notification setInformativeText:attributedStatusString.string];
                [notification setSoundName:@"NSUserNotificationDefaultSoundName"];

                Class UserNotificationCenterClass = NSClassFromString(
                    @"NSUserNotificationCenter"
                );
                
                if (UserNotificationCenterClass)
                {
                    [[UserNotificationCenterClass defaultUserNotificationCenter]
                        setDelegate:self
                    ];
                    [[UserNotificationCenterClass defaultUserNotificationCenter]
                        deliverNotification:notification
                    ];
                }
            }
        }
    }
}

- (void)deliverNotificationIfMentionedMe:(NSDictionary *)aDict
{
    NSString * u = [aDict objectForKey:@"u"];
    NSString * m = [aDict objectForKey:@"m"];
    
    NSString * atU = [NSString stringWithFormat:@"@%@",
        [[NSUserDefaults standardUserDefaults] objectForKey:@"username"]
    ];
    
    if (
        [m rangeOfString:atU options:NSCaseInsensitiveSearch].location != NSNotFound
        )
    {
        Class NSUserNotification = NSClassFromString(@"NSUserNotification");
        
        if (NSUserNotification)
        {
            NSString * informativeText = [NSString
                stringWithFormat:NSLocalizedString(@"@%@ mentioned you.", nil), u
            ];
            
            id notification = [[NSUserNotification alloc] init];
            [notification setTitle:NSLocalizedString(@"Mention", nil)];
            [notification setInformativeText:informativeText];
            [notification setSoundName:@"NSUserNotificationDefaultSoundName"];

            Class UserNotificationCenterClass = NSClassFromString(
                @"NSUserNotificationCenter"
            );
            
            if (UserNotificationCenterClass)
            {
                [[UserNotificationCenterClass defaultUserNotificationCenter]
                    setDelegate:self
                ];
                [[UserNotificationCenterClass defaultUserNotificationCenter]
                    deliverNotification:notification
                ];
            }
        }
    }
}

- (void)didFindProfileNotification:(NSNotification *)aNotification
{
    NSDictionary * dict = aNotification.object;
    
    //NSLog(@"didFindProfileNotification = %@", dict);

    NSString * u = [dict objectForKey:@"u"];

    NSString * username = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"username"
    ];
    
    // Do not sync our profile here, it's done in app delegate.
    if (u && ![u isEqualToString:username])
    {
        BOOL download = NO;
        
        NSDictionary * profile = [[FNProfileCache sharedInstance]
            profile:u
        ];
        
        if (profile && profile.count)
        {
            NSDate * expires1 = [dict objectForKey:@"__t"];
            NSDate * expires2 = [profile objectForKey:@"__t"];

            NSTimeInterval lifetime1 = [[NSDate date]
                timeIntervalSinceDate:expires1
            ];
            
            NSTimeInterval lifetime2 = [[NSDate date]
                timeIntervalSinceDate:expires2
            ];

            if (lifetime1 < lifetime2)
            {
                [[FNProfileCache sharedInstance] setProfile:dict username:u];
                
                download = YES;
                
                NSInteger rowIndex = 0;
                
                for (NSDictionary * message in self.messages)
                {
                    if ([[message objectForKey:@"u"] isEqualToString:u])
                    {
                        [self.tableView reloadDataForRowIndexes:
                            [NSIndexSet indexSetWithIndex:rowIndex]
                            columnIndexes:[NSIndexSet indexSetWithIndex:0]
                        ];
                    }
                    
                    rowIndex++;
                }
            }
        }
        else
        {
            [[FNProfileCache sharedInstance] setProfile:dict username:u];
            
            download = YES;
        }

        if (download)
        {
            NSImage * image = [[FNAvatarCache sharedInstance] objectForKey:
                [dict objectForKey:@"p"]
            ];
            
            if (image)
            {
                // ...
            }
            else
            {
                [self downloadPhoto:[dict objectForKey:@"p"] forUsername:u];
            }
        }
    }
}

- (void)downloadPhoto:(NSString *)aUrl forUsername:(NSString *)aUsername
{
    if ([self.downloadPhotoQueue objectForKey:aUrl])
    {
        return;
    }
    else
    {
        [self.downloadPhotoQueue setObject:aUrl forKey:aUrl];
    }

    NSURL * url = [NSURL URLWithString:aUrl];
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
                image = [image resize:NSMakeSize(128, 128)];
#if 1 // round
                image = [image roundCornersImageCornerRadius:128.0f / 2.0f];
#else
                image = [image roundCornersImageCornerRadius:8.0f];
#endif
                [[FNAvatarCache sharedInstance] setObject:
                    image forKey:aUrl
                ];
                
                NSInteger rowIndex = 0;
                
                for (NSDictionary * message in self.messages)
                {
                    if ([[message objectForKey:@"u"] isEqualToString:aUsername])
                    {
                        [self.tableView reloadDataForRowIndexes:
                            [NSIndexSet indexSetWithIndex:rowIndex]
                            columnIndexes:[NSIndexSet indexSetWithIndex:0]
                        ];
                    }
                    
                    rowIndex++;
                }
            }
        }
    }];
}

#pragma mark -

- (BOOL)textView:(NSTextView *)aTextView
    clickedOnLink:(id)link atIndex:(NSUInteger)charIndex
{
    if (link && [link length])
    {
        if (
            [link rangeOfString:@"pbs.twimg.com" options:
            NSCaseInsensitiveSearch].location != NSNotFound ||
            [link rangeOfString:@".jpg" options:
            NSCaseInsensitiveSearch].location != NSNotFound ||
            [link rangeOfString:@".jpeg" options:
            NSCaseInsensitiveSearch].location != NSNotFound ||
            [link rangeOfString:@".png" options:
            NSCaseInsensitiveSearch].location != NSNotFound ||
            [link rangeOfString:@".gif" options:
            NSCaseInsensitiveSearch].location != NSNotFound ||
            [link rangeOfString:@".pdf" options:
            NSCaseInsensitiveSearch].location != NSNotFound
            )
        {
            NSImage * image = [[NSImage alloc] initWithContentsOfURL:
                [NSURL URLWithString:link]
            ];
            
            if (image)
            {            
                static FNImageWindowController * imageWindowController = nil;
                
                if (!imageWindowController)
                {
                    imageWindowController = [FNImageWindowController new];
                    
                    // load xib
                    [imageWindowController window];
                }
            
                CGRect frame = imageWindowController.window.frame;

                frame.size.width = image.size.width;
                frame.size.height = image.size.height;
                
                CGFloat x = NSWidth(
                    [[imageWindowController.window screen] frame]) / 2 -
                    NSWidth(frame) / 2
                ;
                CGFloat y = NSHeight(
                    [[imageWindowController.window screen] frame]) / 2 -
                    NSHeight(frame) / 2
                ;
                
                frame.origin.x = x;
                frame.origin.y = y;

                imageWindowController.window.title = link;
                [imageWindowController.window setFrame:frame
                    display:YES animate:YES
                ];
                //[imageWindowController.window makeKeyAndOrderFront:nil];
                [imageWindowController showWindow:nil];
                
                imageWindowController.imageView.image = image;
            }
            else
            {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL
                    URLWithString:link]
                ];
            }
        }
        else
        {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:link]];
        }
    }
    
    return YES;
}

- (BOOL)textView:(NSTextView *)aTextView
    clickedOnUsername:(NSString *)aUsername atIndex:(NSUInteger)aIndex
{
    FNAppDelegate * delegate = (FNAppDelegate *)[NSApp delegate];
    
    delegate.searchViewController.searchType = 2;
    
    NSString * username = [aUsername
        stringByReplacingOccurrencesOfString:@" " withString:@""
    ];
    delegate.searchViewController.searchField.stringValue = [username
        stringByReplacingOccurrencesOfString:@"@" withString:@""
    ];

    [delegate goSearch:nil];
    
    [delegate.searchViewController search:
        delegate.searchViewController.searchField
    ];
    
    return YES;
}

- (BOOL)textView:(NSTextView *)aTextView
    clickedOnHashtag:(NSString *)aHashtag atIndex:(NSUInteger)aIndex
{
    FNAppDelegate * delegate = (FNAppDelegate *)[NSApp delegate];
    
    delegate.searchViewController.searchType = 1;
    
    NSString * hashtag = [aHashtag
        stringByReplacingOccurrencesOfString:@" " withString:@""
    ];
    
    delegate.searchViewController.searchField.stringValue = [hashtag
        stringByReplacingOccurrencesOfString:@"#" withString:@""
    ];
    
    [delegate goSearch:nil];
    
    [delegate.searchViewController search:
        delegate.searchViewController.searchField
    ];
    
    return YES;
}

#pragma mark -

- (NSArray *)scanStringForLinks:(NSString *)string
{
	return [string componentsMatchedByRegex:
        @"\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))"
    ];
}

- (NSArray *)scanStringForUsernames:(NSString *)string
{
	return [string componentsMatchedByRegex:@"@{1}([-A-Za-z0-9_]{2,})"];
}

- (NSArray *)scanStringForHashtags:(NSString *)string
{
	return [string componentsMatchedByRegex:@"#{1}([-A-Za-z0-9_]{2,})"];
}

- (IBAction)goProfile:(id)sender
{
    NSInteger rowIndex = [self.tableView rowForView:sender];
    
    NSLog(@"rowIndex = %zu", rowIndex);
    
    NSMutableDictionary * dict = [self.messages objectAtIndex:rowIndex];

    NSString * u = [dict objectForKey:@"u"];
    
    NSMutableDictionary * profile = [[[FNProfileCache sharedInstance]
        profile:u] mutableCopy
    ];
    
    if (profile.count == 0)
    {
        [profile setObject:u forKey:@"u"];
    }
    
    NSLog(@"profile = %@", profile);

    FNAppDelegate * delegate = (FNAppDelegate *)[NSApp delegate];

    [delegate showProfile:profile username:u sender:sender];
}

#pragma mark -

- (NSInteger)search:(NSString *)aQuery clearCurrent:(BOOL)flag
{
    if (flag && self.messages.count > 0)
    {
        NSMutableArray * objects = [NSMutableArray array];
        
        for (id obj in self.messages)
        {
            if (![obj objectForKey:@"isGroup"])
            {
                [objects addObject:obj];
            }
        }
        
        [self.messages removeObjectsInArray:objects];
    
        [self.tableView reloadData];
    }
    
    self.searchTransactionId = [[GVStack sharedInstance] find:aQuery];
    return self.searchTransactionId;
}

- (void)resetGroups
{
    @synchronized(self.messages)
    {
        FNMessageGroup * group24 = [FNMessageGroup new];
        
        group24.hours = 0;
        
        FNMessageGroup * group48 = [FNMessageGroup new];
        
        group48.hours = 24;
        
        FNMessageGroup * group72 = [FNMessageGroup new];
        
        group72.hours = 48;
        
        [group24 setObject:[NSNumber numberWithBool:YES] forKey:@"isGroup"];
        [group24 setObject:NSLocalizedString(@"Today", nil) forKey:@"title"];
        
        [self.messages addObject:group24];
        
        [group48 setObject:NSLocalizedString(@"Yesterday", nil) forKey:@"title"];
        [group48 setObject:[NSNumber numberWithBool:YES] forKey:@"isGroup"];
        
        [self.messages addObject:group48];
        
        [group72 setObject:NSLocalizedString(@"Before Yesterday", nil) forKey:@"title"];
        [group72 setObject:[NSNumber numberWithBool:YES] forKey:@"isGroup"];
        
        [self.messages addObject:group72];

        [self.messages sortUsingDescriptors:[NSArray arrayWithObject:
            [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
        ];
    }
}

- (void)didUnsubscribe:(NSString *)aUsername
{
    NSInteger rowIndex = 0;

    NSMutableIndexSet * indexSet = [NSMutableIndexSet new];
    
    for (NSDictionary * message in self.messages)
    {
        if (![[message objectForKey:@"u"] isEqualToString:aUsername])
        {
            rowIndex++;
            
            continue;
        }
        
        [indexSet addIndex:rowIndex++];
    }
    
    [self.tableView removeRowsAtIndexes:indexSet withAnimation:
        NSTableViewAnimationSlideRight
    ];
    [self.messages removeObjectsAtIndexes:indexSet];
}

- (void)removeExpired
{
    NSInteger rowIndex = 0;

    NSMutableIndexSet * indexSet = [NSMutableIndexSet new];
    
    for (NSDictionary * message in self.messages)
    {
        if ([message objectForKey:@"isGroup"])
        {
            rowIndex++;
            
            continue;
        }
        
        NSTimeInterval _t = [[NSDate date] timeIntervalSinceDate:
            [message objectForKey:@"__t"]
        ];

        NSTimeInterval time = _t / 60.0f / 60.0f;

        BOOL isExpired = time > 60 * 60 * 72;

        if (isExpired)
        {
            NSLog(@"Removing expired message %zu.", rowIndex);
                    
            [indexSet addIndex:rowIndex];
        }
        
        rowIndex++;
    }
    
    [self.messages removeObjectsAtIndexes:indexSet];
    [self.tableView reloadData];
}

- (void)updateTick
{
    [self.messages sortUsingDescriptors:[NSArray arrayWithObject:
        [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
    ];
    
    NSRange visibleRows = [self.tableView rowsInRect:
        [self.tableView.window.contentView bounds]
    ];
    
    [self.tableView beginUpdates];
    [self.tableView reloadDataForRowIndexes:
        [NSIndexSet indexSetWithIndexesInRange:visibleRows] columnIndexes:
        [NSIndexSet indexSetWithIndex:0]
    ];
    [self.tableView noteHeightOfRowsWithIndexesChanged:
        [NSIndexSet indexSetWithIndexesInRange:visibleRows]
    ];
    [self.tableView endUpdates];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
    shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
    didActivateNotification:(NSUserNotification *)notification
{
    switch (notification.activationType)
    {
        case NSUserNotificationActivationTypeContentsClicked:
        {
            NSLog(@"NSUserNotificationActivationTypeContentsClicked");
        }
        break;
        case NSUserNotificationActivationTypeActionButtonClicked:
        {
            NSLog(@"NSUserNotificationActivationTypeActionButtonClicked");
        }
        break;
        default:
        {
            NSLog(@"notification.activationType = %zu", notification.activationType);
        }
        break;
    }
    
    // :TODO: do this when the app is brough to foreground?
    //[center removeDeliveredNotification:notification];
    
    notification = nil;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
    didDeliverNotification:(NSUserNotification *)notification
{
    // :TODO: do this when the app is brough to foreground?
    //[center removeDeliveredNotification:notification];
    
    notification = nil;
}

@end
