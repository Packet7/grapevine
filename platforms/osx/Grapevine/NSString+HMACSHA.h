//
//  NSString+HMACSHA1.h
//  TwitterCommunicator2
//
//  Created by digipeople on 06.12.12.
//  Copyright (c) 2012 digipeople. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HMACSHA)

-(NSData *)HMACSHA512:(NSString *)key;

@end
