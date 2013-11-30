

#import <Cocoa/Cocoa.h>

@protocol FNMessageTextViewDelegate <NSTextViewDelegate>
@optional
- (BOOL)textView:(NSTextView *)aTextView
    clickedOnUsername:(NSString *)aUsername atIndex:(NSUInteger)aIndex
;
- (BOOL)textView:(NSTextView *)aTextView clickedOnHashtag:(NSString *)aHashtag
    atIndex:(NSUInteger)aIndex
;
@end

@interface FNMessageTextView : NSTextView

@property (nonatomic, assign) id<FNMessageTextViewDelegate> delegate;

@end
