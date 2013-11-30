//
//  FNMessageGroup.h
// Grapevine
//
//  Created by Packet7, LLC. on 7/20/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FNMessageGroup : NSMutableDictionary
@property (strong) NSMutableDictionary * dict;
@property (assign) NSInteger hours;

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;

@end
