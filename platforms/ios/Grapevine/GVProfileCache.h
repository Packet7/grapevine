//
//  GVProfileCache.h
//  Grapevine
//
//  Created by Packet7, LLC. on 7/13/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GVProfileCache : NSObject

@property (strong) NSMutableDictionary * profiles;

+ (GVProfileCache *)sharedInstance;

- (NSDictionary *)profile:(NSString *)aUsername;
- (void)setProfile:(NSDictionary *)aDict username:(NSString *)aUsername;

@end
