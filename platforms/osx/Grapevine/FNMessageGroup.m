//
//  FNMessageGroup.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/20/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "FNMessageGroup.h"

@implementation FNMessageGroup

- (id)init
{
    if (self = [super init])
    {
        self.dict = [NSMutableDictionary new];
    }
    return self;
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    [self.dict setObject:anObject forKey:aKey];
}

- (id)objectForKey:(id)aKey
{
    if ([aKey isEqualToString:@"__t"])
    {
        return [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * self.hours)];
    }
    else if ([aKey isEqualToString:@"_l"])
    {
        return [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * self.hours)];
    }
    else if ([aKey isEqualToString:@"_e"])
    {
        return [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * self.hours)];
    }
    else if ([aKey isEqualToString:@"_t"])
    {
        return [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * self.hours)];
    }
    return [self.dict objectForKey:aKey];
}

- (NSUInteger)count
{
    return self.dict.count;
}

//- (id)forwardingTargetForSelector:(SEL)aSelector
//{
//    return self.dict;
//}

- (id)keyEnumerator
{
    return self.dict.keyEnumerator;
}

@end
