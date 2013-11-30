//
//  GVAvatarCache.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/27/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "GVAvatarCache.h"

@implementation GVAvatarCache

+ (GVAvatarCache *)sharedInstance
{
    static GVAvatarCache * gGVAvatarCache = nil;
    
    if (!gGVAvatarCache)
    {
        gGVAvatarCache = [GVAvatarCache new];
    }
    
    return gGVAvatarCache;
}

- (id)init
{
    if (self = [super init])
    {
        self.images = [NSMutableDictionary new];
    }
    return self;
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    [self.images setObject:anObject forKey:aKey];
}

- (id)objectForKey:(id)aKey
{
    return [self.images objectForKey:aKey];
}

@end
