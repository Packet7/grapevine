//
//  FNSidebarTableRowView.h
// Grapevine
//
//  Created by Packet7, LLC. on 7/16/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FNSidebarTableRowView : NSTableRowView {
@private
    BOOL mouseInside;
    NSTrackingArea *trackingArea;
}

@end

// Used by the HoverTableRowView and the HoverTableView
void DrawSeparatorInRect(NSRect rect);
