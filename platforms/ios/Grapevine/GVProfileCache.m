//
//  GVProfileCache.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/13/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "GVProfileCache.h"

@implementation GVProfileCache

+ (GVProfileCache *)sharedInstance
{
    static GVProfileCache * gGVProfileCache = nil;
    
    if (!gGVProfileCache)
    {
        gGVProfileCache = [GVProfileCache new];
    }
    
    return gGVProfileCache;
}

- (id)init
{
    if (self = [super init])
    {
        self.profiles = [NSMutableDictionary new];
    }
    return self;
}

- (NSDictionary *)profile:(NSString *)aUsername
{
    NSDictionary * ret = nil;
    
    ret = [self.profiles objectForKey:aUsername];
    
    if (!ret)
    {
        ret = [NSDictionary dictionary];
        
        [self.profiles setObject:ret forKey:aUsername];
    }
    
    return ret;
}

- (void)setProfile:(NSDictionary *)aDict username:(NSString *)aUsername
{
    [self.profiles setObject:aDict forKey:aUsername];
}

@end
