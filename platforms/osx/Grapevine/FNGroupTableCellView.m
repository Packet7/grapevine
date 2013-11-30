//
//  FNGroupTableCellView.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/20/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "FNGroupTableCellView.h"

@implementation FNGroupTableCellView

- (void)awakeFromNib
{
    //[self.textField.cell setBackgroundStyle:NSBackgroundStyleRaised];

    CGRect frame = self.textField.frame;

    frame.size.height += 4.0f;
    frame.origin.x += 20.0f;
    frame.origin.y -= 8.0f;
    
    self.textField.frame = frame;
 }
 
// - (void)drawRect:(NSRect)dirtyRect
// {
//    CGRect frame = self.bounds;
////
////    [[NSColor clearColor] set];
////
////    NSRectFillUsingOperation(frame, NSCompositeSourceOver);
//////	NSGradient * gradient = [[NSGradient alloc] initWithStartingColor:
//////        _headerGradientStartColor endingColor:_headerGradientEndColor
//////    ];
//////	[gradient drawInRect:frame angle:270.0f];
////
////        [[[NSColor whiteColor] colorWithAlphaComponent:0.65f] set];
////     
////    NSRectFillUsingOperation(frame, NSCompositeSourceOver);
//    frame.size.height = 1.0f;
//    
//    [FNColor(255.0f * 0.78f, 255.0f * 0.78f, 255.0f * 0.78f) set];
////        [[NSColor colorWithCalibratedWhite:1.0f alpha:0.85f] set];
//     
//    NSRectFillUsingOperation(frame, NSCompositeSourceOver);
// }

@end
