//
//  FNSetupFirstViewController.h
//  DPSetupWindow
//
//  Created by Dan Palmer on 05/10/2012.
//  Copyright (c) 2012 Dan Palmer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DPSetupWindow.h"

@interface FNSetupRegisterViewController : NSViewController <DPSetupWindowStageViewController>

@property (assign) IBOutlet NSMatrix * matrix;

@property (readwrite) BOOL canContinue;
@property (readwrite) BOOL canGoBack;

@end
