//
//  NSColor+NSColor_CGColor.m
//  Jittr
//
//  Created by Packet7, LLC. on 12/25/12.
//
//

#import "NSColor+CGColor.h"

@implementation NSColor (NSColor_CGColor)

- (CGColorRef)CGColor
{
	NSColor *colorRGB = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat components[4];
	[colorRGB getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
	CGColorSpaceRef theColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGColorRef theColor = CGColorCreate(theColorSpace, components);
	CGColorSpaceRelease(theColorSpace);
	return (__bridge CGColorRef)(__bridge id)theColor;
}

+ (NSColor*)colorWithCGColor:(CGColorRef)aColor
{
	const CGFloat *components = CGColorGetComponents(aColor);
	CGFloat red = components[0];
	CGFloat green = components[1];
	CGFloat blue = components[2];
	CGFloat alpha = components[3];
	return [self colorWithDeviceRed:red green:green blue:blue alpha:alpha];
}
@end
