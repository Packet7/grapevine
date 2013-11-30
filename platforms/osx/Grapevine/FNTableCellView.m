//
//  FNTableCellView.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/13/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "FNMessageTextView.h"
#import "FNTableCellView.h"

@implementation NSTextView (Geometrics)

- (CGFloat)heightForWidth {

    if ([[self textStorage] length] > 0) {

		// Checking for empty string is necessary since Layout Manager will give the nominal
		// height of one line if length is 0.  Our API specifies 0.0 for an empty string.

		// NSLayoutManager is lazy, so we need the following kludge to force layout:
		[self.layoutManager glyphRangeForTextContainer:self.textContainer];

		return [self.layoutManager usedRectForTextContainer:self.textContainer].size.height;
	}

	return 0;
}

@end

@implementation FNTableCellView

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
    // Drawing code here.
}

+ (CGFloat)heightForText:(NSAttributedString *)text withWidth:(CGFloat)width
{
    CGFloat ret = 0.0f;
    
    NSTextView * textView = [[NSTextView alloc] init];
    
	[[textView textStorage] setAttributedString:text];
	[textView setFrameSize:CGSizeMake(width, 0)];

    ret = [textView heightForWidth];

	return ret;
}

@end
