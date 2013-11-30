//
//  GVTableViewCellContentView.m
//  Grapevine
//
//  Created by Packet7, LLC. on 9/19/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "GVTableViewCellContentView.h"

@implementation GVTableViewCellContentView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setBackgroundColor:[UIColor clearColor]];
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)drawLinearGradientWithContext:(CGContextRef)context
    inRect:(CGRect)rect startColor:(CGColorRef)startColor
    endColor:(CGColorRef)endColor
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, .5, 1.0};

    NSArray *colors = [NSArray arrayWithObjects:(__bridge id)endColor, (__bridge id)startColor, (__bridge id)endColor, nil];

    CGGradientRef gradient = CGGradientCreateWithColors(
        colorSpace, (__bridge CFArrayRef) colors, locations
    );

    CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));

    CGContextSaveGState(context);
    CGContextAddRect(context, rect);
    CGContextClip(context);

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);

    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGRect frame = self.bounds;
    
    CGContextRef context = UIGraphicsGetCurrentContext ();
    
    UIColor * startUIColor = [UIColor
        colorWithRed:0.85f green:0.85f blue:0.85f alpha:1.0f
    ];
    
    UIColor * endUIColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.5f];
    
    context = UIGraphicsGetCurrentContext();
    CGColorRef startColor = startUIColor.CGColor;
    CGColorRef endColor = endUIColor.CGColor;
    
    frame.origin.y = frame.size.height - 1.0f;
    frame.size.height = 1.0f;
    [self drawLinearGradientWithContext:context
        inRect:frame startColor:startColor endColor:endColor
    ];
}
@end
