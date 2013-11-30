//
//  NSImage+RoundCorner.m
//  Round Corner Image
//
//  Created by Venj Chu on 11/08/20.
//  Copyright 2011年 Home. All rights reserved.
//

#import "NSImage+RoundCorner.h"

@implementation NSImage (RoundCorner)

void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

- (NSImage *)roundCornersImageCornerRadius:(NSInteger)radius {
    int w = (int) self.size.width;
    int h = (int) self.size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextBeginPath(context);
    CGRect rect = CGRectMake(0, 0, w, h);
    addRoundedRectToPath(context, rect, radius, radius);
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGImageRef cgImage = [[NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]] CGImage];
    
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), cgImage);
    
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    NSImage *tmpImage = [[NSImage alloc] initWithCGImage:imageMasked size:self.size];
    NSData *imageData = [tmpImage TIFFRepresentation];
    NSImage *image = [[NSImage alloc] initWithData:imageData];
    
    return image;
}

- (NSImage *)resize:(NSSize)aSize
{
    [self setScalesWhenResized:YES];

    if (![self isValid])
    {
        NSLog(@"Invalid Image");
    }
    else
    {
        NSImage * smallImage = [[NSImage alloc] initWithSize:aSize];
        [smallImage lockFocus];
        [self setSize:aSize];
        [[NSGraphicsContext currentContext]
            setImageInterpolation:NSImageInterpolationHigh
        ];
        [self drawAtPoint:NSZeroPoint fromRect:
            CGRectMake(0, 0, aSize.width, aSize.height) operation:
            NSCompositeCopy fraction:1.0
        ];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}

@end
