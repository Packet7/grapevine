//
//  FNTitleBarView.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/17/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "FNTitleBarView.h"

@implementation FNTitleBarView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) awakeFromNib
{
    [[title cell] setBackgroundStyle:NSBackgroundStyleRaised];
}

- (void) drawRect:(NSRect)dirtyRect
{
    if ([NSApp isActive] && [[self window] isMainWindow])
    {
        [title setEnabled:YES];
    }
    else
    {
        [title setEnabled:NO];
    }
}

@end
