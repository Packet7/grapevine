//
//  FNSearchViewController.h
// Grapevine
//
//  Created by Packet7, LLC. on 7/15/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FNSearchViewController : NSViewController <NSTextFieldDelegate>

@property (assign) NSInteger searchType;

@property (assign) IBOutlet NSSearchField * searchField;
@property (assign) IBOutlet NSMenu * menu;

- (IBAction)selectSearchType:(id)sender;

- (IBAction)search:(id)sender;

- (void)searchKeyword:(NSString *)aKeyword;

@end
