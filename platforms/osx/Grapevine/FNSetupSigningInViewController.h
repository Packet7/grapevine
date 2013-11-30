//
//  FNSetupSigningInViewController.h
// Grapevine
//
//  Created by Packet7, LLC. on 7/22/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DPSetupWindow.h"

@interface FNSetupSigningInViewController
     : NSViewController <DPSetupWindowStageViewController>

- (void)signInWithUsername:(NSString *)aUsername password:(NSString *)aPassword;

@property (readwrite) BOOL canContinue;
@property (readwrite) BOOL canGoBack;

@end
