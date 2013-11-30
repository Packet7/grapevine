//
//  GVMessageTextView.h
//  Grapevine
//
//  Created by Packet7, LLC. on 7/28/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GVMessageTextViewDelegate <UITextViewDelegate>
@optional
- (void)textView:(UITextView *)aTextView
    clickedOnLink:(NSString *)aLink
;
- (void)textView:(UITextView *)aTextView
    clickedOnUsername:(NSString *)aUsername
;
- (void)textView:(UITextView *)aTextView clickedOnHashtag:(NSString *)aHashtag
;
@end

@interface GVMessageTextView : UITextView

@end
