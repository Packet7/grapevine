//
//  FNTableHeaderView.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/18/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "FNTableHeaderView.h"

@implementation FNTableHeaderView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGRect rect = self.bounds;

    rect.size.height = 1.0f;
    
    [[NSColor lightGrayColor] set];
    
    NSRectFill(rect);
}

@end
