//
//  GVTimelineTableViewCell.h
//  Grapevine
//
//  Created by Packet7, LLC. on 7/26/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DAContextMenuCell.h"

@interface GVTimelineTableViewCell : DAContextMenuCell

@property (assign) IBOutlet UIButton * avatarButton;
@property (assign) IBOutlet UIImageView * avatarImageView;
@property (assign) IBOutlet UILabel * timeLabel;
@property (assign) IBOutlet UITextView * messageTextView;
@end
