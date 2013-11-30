//
//  GVAlert.h
//  Grapevine
//
//  Created by Packet7, LLC. on 8/29/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GVAlert : NSObject <UIAlertViewDelegate>

+ (GVAlert *)sharedInstance;

extern NSString * kGVDidReviewTOS02;

- (void)showWithTOS;
- (void)showWithFileSizeTooLarge;

@end
