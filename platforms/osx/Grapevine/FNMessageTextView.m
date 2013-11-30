//
//  FNMessageTextView.m
//  TweetView
//
//  Created by Mike Rundle on 12/2/10.
//
//  My license: do whatever you want with this code, you don't have to give me credit. It might
//  blow up or set your computer on fire so it's provided AS IS.

#import "FNMessageTextView.h"

@implementation FNMessageTextView

// We're only subclassing NSTextView so we can grab its mouse down event. Everything
// else will be handled like normal
- (void)mouseDown:(NSEvent *)theEvent {
	// Grab a usable NSPoint value for our mousedown event
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
    NSLog(@"mouseDown");
    
	// Starting in 10.5, NSTextView provides this nifty function to get the index of
	// the character at a specific NSPoint. It automatically takes into account all the
	// custom drawing attributes of our attributed string including line spacing.
	NSInteger charIndex = [self characterIndexForInsertionAtPoint:point];
	
	// If we actually clicked on a text character
	if (NSLocationInRange(charIndex, NSMakeRange(0, [[self string] length])) == YES ) {
		
		// Grab the attributes of our attributed string at this exact index
		NSDictionary *attributes = [[self attributedString] attributesAtIndex:charIndex effectiveRange:NULL];
		
		// Depending on what they clicked we could open a URL or perhaps pop open a profile HUD
		// if they clicked on a username. For now, we'll just throw it out to the log.
		if( [attributes objectForKey:@"LinkMatch"] != nil ) {
			// Remember what object we stashed in this attribute? Oh yeah, it's a URL string. Boo ya!
			NSLog( @"LinkMatch: %@", [attributes objectForKey:@"LinkMatch"] );
        
            if (
                [self.delegate respondsToSelector:
                @selector(textView:clickedOnLink:atIndex:)]
                )
            {
                [self.delegate textView:self clickedOnLink:
                    [attributes objectForKey:@"LinkMatch"] atIndex:charIndex
                ];
            }
		}
        
		if ([attributes objectForKey:@"UsernameMatch"] != nil ) {
			NSLog( @"UsernameMatch: %@", [attributes objectForKey:@"UsernameMatch"] );
            
            if (
                [self.delegate respondsToSelector:
                @selector(textView:clickedOnUsername:atIndex:)]
                )
            {
                [self.delegate textView:self clickedOnUsername:
                    [attributes objectForKey:@"UsernameMatch"] atIndex:charIndex
                ];
            }
		}
		
		if( [attributes objectForKey:@"HashtagMatch"] != nil ) {
			NSLog( @"HashtagMatch: %@", [attributes objectForKey:@"HashtagMatch"] );
            
            if (
                [self.delegate respondsToSelector:
                @selector(textView:clickedOnHashtag:atIndex:)]
                )
            {
                [self.delegate textView:self clickedOnHashtag:
                    [attributes objectForKey:@"HashtagMatch"] atIndex:charIndex
                ];
            }
		}
	}
	
	[super mouseDown:theEvent];
}

@end
