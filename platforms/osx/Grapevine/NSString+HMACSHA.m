//
//  NSString+HMACSHA1.m
//  TwitterCommunicator2
//
//  Created by digipeople on 06.12.12.
//  Copyright (c) 2012 digipeople. All rights reserved.
//

#import "NSString+HMACSHA.h"

#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (HMACSHA)

-(NSData *)HMACSHA512:(NSString *)key
{
    const char *cKey  = [key UTF8String];
    const char *cData = [self UTF8String];
    
    unsigned char cHMAC[CC_SHA512_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA512, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)];
    
    return HMAC;
}

@end
