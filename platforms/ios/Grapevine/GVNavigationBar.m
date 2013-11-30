//
//  GVNavigationBar.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/31/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "GVNavigationBar.h"

@implementation GVNavigationBar

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
	
    if (self)
	{
//        self.tintColor = [UIColor colorWithRed:0.641747f green:0.0f
//            blue:0.399048f alpha:1.0f
//        ];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
//    // light color: r = 0.48, g = 0.00, b = 0.33
//    UIColor * color = [UIColor colorWithRed:0.48f green:0.0f blue:0.33f alpha:1.0f];
//    
//    [color setFill];
//    
//    UIRectFill(rect);
//    
//    // r = 0.641747, g = 0, b = 0.399048
//    color = [UIColor colorWithRed:0.641747f green:0.0f blue:0.399048f alpha:1.0f];
//    
//    [color setFill];
//
//    CGRect newRect = rect;
//    newRect.size.height -= 1.0f;
//    
//    UIRectFill(newRect);

    [[UIColor colorWithWhite:0.85f alpha:1.0f] set];
    UIRectFill(self.bounds);
}
@end
