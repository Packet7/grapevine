//
//  NSColor+NSColor_CGColor.h
//  Jittr
//
//  Created by Packet7, LLC. on 12/25/12.
//
//


#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

/**
 NSColor category for converting NSColor<-->CGColor
 */

@interface NSColor (NSColor_CGColor)
/**
 Return CGColor representation of the NSColor in the RGB color space
 */
@property (readonly) CGColorRef CGColor;
/**
 Create new NSColor from a CGColorRef
 */
+ (NSColor*)colorWithCGColor:(CGColorRef)aColor;

@end