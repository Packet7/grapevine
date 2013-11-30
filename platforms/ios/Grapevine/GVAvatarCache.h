//
//  GVAvatarCache.h
//  Grapevine
//
//  Created by Packet7, LLC. on 7/27/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GVAvatarCache : NSObject

@property (strong) NSMutableDictionary * images;

+ (GVAvatarCache *)sharedInstance;

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;

- (id)objectForKey:(id)aKey;

@end
