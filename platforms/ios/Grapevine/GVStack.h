//
//  GVStack.h
// Grapevine
//
//  Created by Packet7, LLC. on 7/13/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

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
