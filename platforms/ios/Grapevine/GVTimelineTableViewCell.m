//
//  GVTimelineTableViewCell.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/26/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "GVTableViewCellContentView.h"
#import "GVTimelineTableViewCell.h"

@implementation GVTimelineTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundView = [[GVTableViewCellContentView alloc] init];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundView = [[GVTableViewCellContentView alloc] init];
    
    self.timeLabel.font = [UIFont fontWithName:@"Droid Sans"
        size:12.0f
    ];
    self.messageTextView.font = [UIFont fontWithName:@"Droid Sans"
        size:14.0f
    ];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
