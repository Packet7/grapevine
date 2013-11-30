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

#import <Foundation/Foundation.h>

@interface FNMessageController
    : NSObject <NSTableViewDataSource, NSTableViewDelegate, NSUserNotificationCenterDelegate>

@property (strong) IBOutlet NSTableView * tableView;
@property (strong) NSMutableArray * messages;

typedef enum
{
    FNMessageControllerTypeFeed,
    FNMessageControllerTypeSearch,
} FNMessageControllerType;

@property (assign) FNMessageControllerType messageControllerType;

/**
 * Performs a lookup in the network for the query.
 */
- (NSInteger)search:(NSString *)aQuery clearCurrent:(BOOL)flag;

/**
 * Called when a username is unsubscribed.
 */
- (void)didUnsubscribe:(NSString *)aUsername;

@end
