//
//  FNProfileViewController.h
// Grapevine
//
//  Created by Packet7, LLC. on 7/16/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FNProfileViewController : NSViewController

@property (strong) NSDictionary * profile;

@property (strong) IBOutlet NSImageView * avatarImageView;

- (IBAction)subscribe:(id)sender;

- (void)setup:(NSString *)aUsername profile:(NSDictionary *)aProfile;

- (IBAction)hide:(id)sender;

@end
