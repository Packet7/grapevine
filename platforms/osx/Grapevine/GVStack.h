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

@interface GVStack : NSObject

@property (copy) NSString * username;
@property (strong, readonly) NSDictionary * subscriptions;
@property (assign) BOOL isConnected;

extern NSString * kGVDidConnectNotification;
extern NSString * kGVDidDisconnectNotification;
extern NSString * kGVDidSignInNotification;
extern NSString * kGVDidFindMessageNotification;
extern NSString * kGVDidFindProfileNotification;
extern NSString * kGVOnVersionNotification;

+ (GVStack *)sharedInstance;

- (void)start;
- (void)start:(NSNumber *)aPort;
- (void)stop;

- (void)signIn:(NSString *)aUsername password:(NSString *)aPassword;
- (void)signOut;

- (NSUInteger)find:(NSString *)aQuery;

- (void)subscribe:(NSString *)aUsername;
- (void)unsubscribe:(NSString *)aUsername;

- (void)refresh;

- (void)post:(NSString *)aMessage;

- (void)updateProfile:(NSDictionary *)aProfile;
- (void)updateProfile;

@end
