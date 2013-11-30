//
//  DAСontextMenuCell.m
//  DAContextMenuTableViewControllerDemo
//
//  Created by Daria Kopaliani on 7/24/13.
//  Copyright (c) 2013 Daria Kopaliani. All rights reserved.
//

#import "DAContextMenuCell.h"

@interface DAContextMenuCell ()

@property (strong, nonatomic) UIView *contextMenuView;
@property (strong, nonatomic) UIButton *moreOptionsButton;
@property (assign, nonatomic, getter = isContextMenuHidden) BOOL contextMenuHidden;

@end


@implementation DAContextMenuCell

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setUp];
}

- (void)setUp
{
    //self.actualContentView = self.contentView;
    
    CGRect frame = self.actualContentView.bounds;
 
    self.contextMenuView = [[UIView alloc] initWithFrame:frame];
    self.contextMenuView.backgroundColor = [UIColor clearColor];
    [self.contentView insertSubview:self.contextMenuView belowSubview:self.actualContentView];
    self.backgroundColor = [UIColor whiteColor];
    self.contextMenuHidden = self.contextMenuView.hidden = YES;
    self.editable = YES;
    self.moreOptionsButtonTitle = NSLocalizedString(@"More", nil);
    [self addGestureRecognizers];
    [self setNeedsLayout];
}

#pragma mark - Public

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.contextMenuView.frame = self.actualContentView.bounds;
    [self.contentView sendSubviewToBack:self.contextMenuView];
    [self.contentView bringSubviewToFront:self.actualContentView];
    
    CGFloat height = CGRectGetHeight(self.bounds) - 1.0f;
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat menuOptionButtonWidth = [self menuOptionButtonWidth];
    self.moreOptionsButton.frame = CGRectMake(width - menuOptionButtonWidth, 0., menuOptionButtonWidth, height);
}

- (void)setMoreOptionsButtonTitle:(NSString *)moreOptionsButtonTitle
{
    _moreOptionsButtonTitle = moreOptionsButtonTitle;
#if 0
    [self.moreOptionsButton setImage:[UIImage imageNamed:@"Republish"] forState:UIControlStateNormal];
#else
    [self.moreOptionsButton setTitle:self.moreOptionsButtonTitle forState:UIControlStateNormal];
#endif
    [self setNeedsLayout];
}

- (CGFloat)menuOptionButtonWidth
{
    NSString *string =  self.moreOptionsButtonTitle;
    CGFloat offset = 15.;
    CGFloat width = [string sizeWithFont:self.moreOptionsButton.titleLabel.font].width + offset;
    if (width > 90.) {
        width = 90.;
    }
    return width;
}

- (void)setMenuOptionsViewHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (self.selected) {
        [self setSelected:NO animated:NO];
    }

    if (hidden != self.isContextMenuHidden) {
        self.contextMenuHidden = hidden;
        if (!hidden) {
            self.contextMenuView.hidden = NO;
        }
        CGFloat contextMenuWidth = CGRectGetWidth(self.moreOptionsButton.frame);
        [UIView animateWithDuration:(animated) ? 0.3 : 0. animations:^{
            CGRect frame = self.actualContentView.frame;
            frame.origin.x = (hidden) ? 0. : -contextMenuWidth;
            self.actualContentView.frame = frame;
        } completion:^(BOOL finished) {
            self.actualContentView.userInteractionEnabled = hidden;
            self.contextMenuView.hidden = hidden;
            if (!hidden) {
                self.moreOptionsButton.userInteractionEnabled = YES;
                [self.delegate contextMenuDidShowInCell:self];
            }
        }];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (self.contextMenuHidden) {
        [super setHighlighted:highlighted animated:animated];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.contextMenuHidden) {
        [super setSelected:selected animated:animated];
    }
}

#pragma mark - Private

- (void)addGestureRecognizers
{
    UISwipeGestureRecognizer *leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                              action:@selector(showMenuOptionsView)];
    leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:leftSwipeRecognizer];
    UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(hideMenuOptionsView)];
    rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:rightSwipeRecognizer];
}

- (void)moreButtonTapped
{
    [self.delegate contextMenuCellDidSelectMoreOption:self];
}

- (void)hideMenuOptionsView
{
    [self setMenuOptionsViewHidden:YES animated:YES];
}

- (void)showMenuOptionsView
{
    if ([self.delegate shouldShowMenuOptionsViewInCell:self]) {
        [self setMenuOptionsViewHidden:NO animated:YES];
    }
}

#pragma mark * Lazy getters

- (UIButton *)moreOptionsButton
{
    if (!_moreOptionsButton) {
        CGRect frame = CGRectMake(0., 0., 100., CGRectGetHeight(self.actualContentView.frame));
        _moreOptionsButton = [[UIButton alloc] initWithFrame:frame];
        _moreOptionsButton.titleLabel.font = [UIFont fontWithName:@"Droid Sans" size:14.0f];
#if 1
        _moreOptionsButton.backgroundColor = [UIColor lightGrayColor];
#else
        _moreOptionsButton.backgroundColor = [UIColor colorWithRed:0.4f
            green:0.84f blue:0.41f alpha:1.0f
        ];
#endif
        [self.contextMenuView addSubview:_moreOptionsButton];
        [_moreOptionsButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreOptionsButton;
}

@end