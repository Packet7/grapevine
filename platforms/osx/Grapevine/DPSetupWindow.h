//
//  DPSetupWindowView.h
//  DPSetupWindow
//
//  Created by Dan Palmer on 05/10/2012.
//  Copyright (c) 2012 Dan Palmer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DPSetupWindow;

@protocol DPSetupWindowStageViewController <NSObject>
@optional

/*
 Stage view controllers must implement these as they will be observed by the setup window to determine whether the interface buttons should be enabled.
 */
@property (readonly) BOOL canContinue;
@property (readonly) BOOL canGoBack;

/*
 Each view controller will be given a reference to the setup window through this method so that it may add extra stages for a dynamic setup process.
 */
- (void)setSetupWindow:(DPSetupWindow *)setupWindow;

/*
 These methods allow each stage to define their own titles for the interface buttons. For example, one may wish to have "Next, Next and Finish" as the continue button titles for three stages.
 
 *Note: a custom title will not get carried over to the next stage, each stage must specify it's own.*
 */
- (NSString *)continueButtonTitle;
- (NSString *)backButtonTitle;
- (NSString *)cancelButtonTitle;

/*
 These methods are used to notify the view controllers in the setup flow of any changes they may be interested in.
 
 To illustrate the times each method will be called, the italicised stage is the one that will receive the method call.
 
 *current* -> next
 */
- (void)willProgressToNextStage;
- (void)didProgressToNextStage;

/*
 current -> *next*
 */
- (void)willProgressToStage;
- (void)didProgressToStage;

/*
 previous <- *current*
 */
- (void)willRevertToPreviousStage;
- (void)didRevertToPreviousStage;

/*
 *previous* <- current
 */
- (void)willRevertToStage;
- (void)didRevertToStage;

@end

@interface DPSetupWindow : NSWindow {
	NSImage *_backgroundImage;
	NSInteger currentStage;
}

@property (strong) NSImage *backgroundImage;
@property (assign) BOOL animates;
@property (strong) NSArray *viewControllers;
@property (assign) BOOL funnelsRepresentedObjects;

- (id)initWithViewControllers:(NSArray *)viewControllers completionHandler:(void (^)(BOOL completed))completionHandler;

- (void)addNextViewController:(NSViewController<DPSetupWindowStageViewController> *)viewController;
- (void)removeViewController:(NSViewController<DPSetupWindowStageViewController> *)viewController;
- (void)addFinalViewController:(NSViewController<DPSetupWindowStageViewController> *)viewController;
- (void)progressToNextStage;
- (void)revertToPreviousStage;

@end
