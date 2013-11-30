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

#import "FNProfileCache.h"

@implementation FNProfileCache

+ (FNProfileCache *)sharedInstance
{
    static FNProfileCache * gFNProfileCache = nil;
    
    if (!gFNProfileCache)
    {
        gFNProfileCache = [FNProfileCache new];
    }
    
    return gFNProfileCache;
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
