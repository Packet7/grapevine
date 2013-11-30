//
//  FNNewWindowController.h
// Grapevine
//
//  Created by Packet7, LLC. on 7/14/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FNNewWindowController : NSWindowController <NSTextFieldDelegate>

@property (assign) IBOutlet NSViewController * viewController;
@property (strong) NSPopover * popover;
@property (assign) IBOutlet NSTextField * messageTextField;

- (IBAction)shorten:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)post:(id)sender;
- (IBAction)pickFile:(id)sender;

@end
