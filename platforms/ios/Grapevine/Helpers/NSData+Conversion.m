//
//  NSData+NSData_Conversion.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/24/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "NSData+Conversion.h"

@implementation NSData (Conversion)

- (NSString *)hexString
{
    NSMutableString * ret = [NSMutableString string];
    
    const unsigned char * ptr = (const unsigned char *)[self bytes];

    for (NSUInteger i = 0; i < self.length; i++)
    {
        [ret appendFormat:@"%02x" , ptr[i] & 0x00FF];
    }

    return ret;
}

@end
