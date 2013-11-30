//
//  GVMessageTextView.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/28/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "GVMessageTextView.h"

@implementation GVMessageTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

static BOOL stringCharacterIsAllowedAsPartOfLink(NSString * s)
{
    if (s == nil || s.length < 1)
    {
        return NO;
    }
    
    unichar ch = [s characterAtIndex:0];
    
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ch])
    {
        return NO;
    }
    
    return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.nextResponder touchesEnded:touches withEvent:event];	

    [super touchesEnded:touches withEvent:event];
    
    UITouch * touch = [touches anyObject];
    
    CGPoint point = [touch locationInView:self];
    
    NSString * link = [self potentialLinkAtPoint:point];

    if (
        link && [link rangeOfString:@"http" options:
        NSCaseInsensitiveSearch].location != NSNotFound
        )
    {
        if ([self.delegate respondsToSelector:@selector(textView:clickedOnLink:)])
        {
            [self.delegate performSelector:
                @selector(textView:clickedOnLink:) withObject:self
                withObject:link
            ];
        }
    }
    else if (
        link && [link rangeOfString:@"@" options:
        NSCaseInsensitiveSearch].location != NSNotFound
        )
    { 
        if ([self.delegate respondsToSelector:@selector(textView:clickedOnUsername:)])
        {
            [self.delegate performSelector:
                @selector(textView:clickedOnUsername:) withObject:self
                withObject:link
            ];
        }
    }
    else if (
        link && [link rangeOfString:@"#" options:
        NSCaseInsensitiveSearch].location != NSNotFound
        )
    {
        if ([self.delegate respondsToSelector:@selector(textView:clickedOnHashtag:)])
        {
            [self.delegate performSelector:
                @selector(textView:clickedOnHashtag:) withObject:self
                withObject:link
            ];
        }
    }
}

- (NSString *)potentialLinkAtPoint:(CGPoint)point
{
    UITextRange * textRange = [self characterRangeAtPoint:point];
    UITextPosition * endOfDocumentTextPosition = self.endOfDocument;
    
    if ([textRange.end isEqual:endOfDocumentTextPosition])
    {
        return nil;
    }
    
    UITextPosition * tapPosition = [self closestPositionToPoint:point];
    
    if (tapPosition == nil)
    {
        return nil;
    }
    
    NSMutableString * s = [NSMutableString stringWithString:@""];
 
    /* Move right*/
 
    UITextPosition *textPosition = tapPosition;
 
    BOOL isFirstCharacter = YES;
    
    while (true)
    {
        UITextRange * rangeOfCharacter = [self.tokenizer
            rangeEnclosingPosition:textPosition withGranularity:
            UITextGranularityCharacter inDirection:UITextWritingDirectionNatural
        ];
        
        NSString * oneCharacter = [self textInRange:rangeOfCharacter];
 
        if (isFirstCharacter)
        {
            /*If first character is cr or lf, then we're off the right hand
            side of the link. Maybe way outside.*/
            if (
                [oneCharacter isEqualToString:@"\n"] ||
                [oneCharacter isEqualToString:@"\r"]
                )
            {
                return nil;
            }
        }
 
        isFirstCharacter = NO;
        
        if (!stringCharacterIsAllowedAsPartOfLink(oneCharacter))
        {
            break;
        }
        
        [s appendString:oneCharacter];
 
        textPosition = [self positionFromPosition:textPosition offset:1];
        
        if (textPosition == nil)
        {
            break;
        }
    }
 
    /*Move left*/
 
    textPosition = [self positionFromPosition:tapPosition offset:-1];
    
    if (textPosition != nil)
    {
        while (true)
        {
            UITextRange * rangeOfCharacter = [self.tokenizer
                rangeEnclosingPosition:textPosition withGranularity:
                UITextGranularityCharacter inDirection:
                UITextWritingDirectionNatural
            ];
            
            NSString * oneCharacter = [self textInRange:rangeOfCharacter];
 
            if (!stringCharacterIsAllowedAsPartOfLink(oneCharacter))
            {
                break;
            }
            
            [s insertString:oneCharacter atIndex:0];
 
            textPosition = [self positionFromPosition:textPosition offset:-1];
            
            if (textPosition == nil)
            {
                break;
            }
        }
    }
 
    return s;
}

@end
