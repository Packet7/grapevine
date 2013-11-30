//
//  FNTableCellView.h
// Grapevine
//
//  Created by Packet7, LLC. on 7/13/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FNMessageTextView;

@interface FNTableCellView : NSTableCellView

@property (strong) IBOutlet NSImageView * avatarImageView;
@property (strong) IBOutlet IBOutlet NSButton * avatarButton;
@property (strong) IBOutlet NSTextField * usernameTextField;
@property (strong) IBOutlet FNMessageTextView * messageTextField;
@property (strong) IBOutlet NSTextField * timestampTextField;
+ (CGFloat)heightForText:(NSAttributedString *)text withWidth:(CGFloat)width;

@end
