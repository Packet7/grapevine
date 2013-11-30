//
//  GVProfileTableViewCell.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/29/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "GVProfileTableViewCell.h"
#import "GVTableViewCellContentView.h"

@implementation GVProfileTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView = [[GVTableViewCellContentView alloc] init];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
