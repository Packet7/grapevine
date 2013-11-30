//
//  FNSidebarTableRowView.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/16/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "FNSidebarTableRowView.h"


@interface FNSidebarTableRowView ()
@property BOOL mouseInside;

@property (strong) NSButton * actionButton;

@end

@implementation FNSidebarTableRowView

@dynamic mouseInside;

- (void)setMouseInside:(BOOL)value {
    if (mouseInside != value) {
        mouseInside = value;
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)mouseInside {
    return mouseInside;
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    self.mouseInside = YES;
    
    if (!self.isGroupRowStyle)
    {
        #define ACTION_BUTTON_PADDING 10.0f
        #define ACTION_BUTTON_WIDTH 16.0f
        
        if (
            !self.actionButton && [self.superview isKindOfClass:NSTableView.class]
            )
        {
             self.actionButton = [[NSButton alloc] initWithFrame:NSZeroRect];
            
            self.actionButton.autoresizingMask =
                NSViewMinXMargin | NSViewMinYMargin | NSViewMaxYMargin
            ;
            self.actionButton.image = [NSImage imageNamed:@"Action"];
            self.actionButton.bezelStyle = NSInlineBezelStyle;
            [self.actionButton setBordered:NO];
            [self.actionButton.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
            //[actionButton setHidden:YES];
            self.actionButton.alphaValue = 0.35f;
            [self.actionButton setTarget:((NSTableView *)self.superview).delegate];
            [self.actionButton setAction:@selector(showActionMenu:)];
            [self addSubview:self.actionButton];
        }
        
        [self.actionButton setHidden:NO];
        
        CGRect frame = NSMakeRect(
            self.frame.size.width -
            (ACTION_BUTTON_PADDING + ACTION_BUTTON_WIDTH),
            self.frame.size.height - (ACTION_BUTTON_PADDING + ACTION_BUTTON_WIDTH),
            ACTION_BUTTON_WIDTH, 16.0f
        );
        
        self.actionButton.frame = frame;
        
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    self.mouseInside = NO;
    
    if (!self.isGroupRowStyle)
    {
        [self.actionButton setHidden:YES];
    }
}

static NSGradient *gradientWithTargetColor(NSColor *targetColor) {
    NSArray *colors = [NSArray arrayWithObjects:[targetColor colorWithAlphaComponent:0], targetColor, targetColor, [targetColor colorWithAlphaComponent:0], nil];
    const CGFloat locations[4] = { 0.0, 0.35, 0.65, 1.0 };
    return [[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace sRGBColorSpace]];
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
    if (self.isGroupRowStyle)
    {
        [[NSColor colorWithCalibratedWhite:1.0f alpha:0.85f] set];
        NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);
    }
    else
    {
#if 1
        [[NSColor whiteColor] set];
        NSRectFill(self.bounds);
#else
        // Custom background drawing. We don't call super at all.
        [self.backgroundColor set];
        // Fill with the background color first
        NSRectFill(self.bounds);
        
        // Draw a white/alpha gradient
        if (self.mouseInside && !self.isGroupRowStyle) {
            NSGradient *gradient = gradientWithTargetColor([NSColor colorWithCalibratedWhite:0.95f alpha:0.75f]);
            [gradient drawInRect:self.bounds angle:0];
        }
#endif
    }
}

- (NSRect)separatorRect {
    NSRect separatorRect = self.bounds;
    separatorRect.origin.y = NSMaxY(separatorRect) - 1;
    separatorRect.size.height = 1;
    return separatorRect;
}

// Only called if the table is set with a horizontal grid
- (void)drawSeparatorInRect:(NSRect)dirtyRect {
    // Use a common shared method of drawing the separator
    DrawSeparatorInRect([self separatorRect]);
}

// Only called if the 'selected' property is yes.
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    // Check the selectionHighlightStyle, in case it was set to None
    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
        // We want a hard-crisp stroke, and stroking 1 pixel will border half on one side and half on another, so we offset by the 0.5 to handle this
        NSRect selectionRect = NSInsetRect(self.bounds, 5.5, 5.5);
        [[NSColor colorWithCalibratedWhite:.72 alpha:1.0] setStroke];
        [[NSColor colorWithCalibratedWhite:.82 alpha:1.0] setFill];
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:10 yRadius:10];
        [selectionPath fill];
        [selectionPath stroke];
    }
}

// interiorBackgroundStyle is normaly "dark" when the selection is drawn (self.selected == YES) and we are in a key window (self.emphasized == YES). However, we always draw a light selection, so we override this method to always return a light color.
- (NSBackgroundStyle)interiorBackgroundStyle
{
    return NSBackgroundStyleLight;  
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    // We need to invalidate more things when live-resizing since we fill with a gradient and stroke
    if ([self inLiveResize]) {
        // Redraw everything if we are using a gradient
        if (self.selected || self.mouseInside) {
            [self setNeedsDisplay:YES];
        } else {
            // Redraw our horizontal grid line, which is a gradient
            [self setNeedsDisplayInRect:[self separatorRect]];
        }
    }
}

@end

void DrawSeparatorInRect(NSRect rect) {
    // Cache the gradient for performance
    static NSGradient *gradient = nil;
    if (gradient == nil) {
        gradient = gradientWithTargetColor([NSColor colorWithSRGBRed:0.85f green:0.85f blue:0.85f alpha:1]);
    }
    [gradient drawInRect:rect angle:0];
    
}