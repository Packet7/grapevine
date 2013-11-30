//
//  GVTimelineTableViewController.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/26/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <objc/runtime.h>

#import "IDMPhotoBrowser.h"
#import "RegexKitLite.h"
#import "UIImageView+WebCache.h"

#import "GVAppDelegate.h"
#import "GVComposeViewController.h"
#import "GVProfileCache.h"
#import "GVProfileViewController.h"
#import "GVTimelineTableHeaderView.h"
#import "GVTimelineTableViewCell.h"
#import "GVTimelineTableViewController.h"

@interface GVTimelineTableViewController ()
@property (strong) NSMutableArray * today;
@property (strong) NSMutableArray * yesterday;
@property (strong) NSMutableArray * beforeYesterday;
@property (assign) NSInteger searchTransactionId;
@property (strong) UIPopoverController * profilePopoverController;
@property (nonatomic, retain) UITapGestureRecognizer * gestureRecognizer;
@property (strong) REComposeViewController * composeViewController;
@property (strong) NSTimer * expiredMessageTimer;
@property (strong) NSTimer * updateTimer;

+ (NSArray *)scanStringForLinks:(NSString *)string;
+ (NSArray *)scanStringForUsernames:(NSString *)string;
+ (NSArray *)scanStringForHashtags:(NSString *)string;

@end

@implementation GVTimelineTableViewController

- (id)initWithStyle:(UITableViewStyle)style viewControllerType:(GVViewControllerType)viewControllerType
{
    self = [super initWithStyle:style];
    if (self)
    {
        self.viewControllerType = viewControllerType;
        
        [self.tableView registerNib:[UINib nibWithNibName:
            @"TimelineTableViewCell" bundle:[NSBundle mainBundle]]
            forCellReuseIdentifier:@"GVTimelineTableViewCell"
        ];
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        self.today = [NSMutableArray new];
        self.yesterday = [NSMutableArray new];
        self.beforeYesterday = [NSMutableArray new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didFindMessageNotification:)
            name:kGVDidFindMessageNotification object:nil
        ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didFindProfileNotification:)
            name:kGVDidFindProfileNotification object:nil
        ];
        
        self.expiredMessageTimer = [NSTimer
            scheduledTimerWithTimeInterval:60.0f target:self
            selector:@selector(removeExpired) userInfo:nil repeats:YES
        ];
        
        self.updateTimer = [NSTimer
            scheduledTimerWithTimeInterval:10.0f target:self
            selector:@selector(updateTick) userInfo:nil repeats:YES
        ];
#if 0 //
        NSMutableDictionary * message = [NSMutableDictionary dictionary];
        
        // Today
        [message setObject:@"luke" forKey:@"u"];
        [message setObject:@"I have a headache. Been starting at a #screen too long." forKey:@"m"];
        [message setObject:[self.class attributedStringWithMessage:
            [message objectForKey:@"m"]] forKey:@"attributedMessage"
        ];
        [message setObject:[NSDate date] forKey:@"__t"];        
        
        [self.today addObject:message];
        
        message = [NSMutableDictionary dictionary];
        
        // Today
        [message setObject:@"ashani" forKey:@"u"];
        [message setObject:@"Loving Angry birds seasons Since I love angry birds I love this new app of it here is the link http://goo.gl/mbgHEI … #app #Angry birds" forKey:@"m"];
        [message setObject:[self.class attributedStringWithMessage:
            [message objectForKey:@"m"]] forKey:@"attributedMessage"
        ];
        [message setObject:[NSDate date] forKey:@"__t"];
        
        [self.today addObject:message];
        
        message = [NSMutableDictionary dictionary];
        
        // Today
        [message setObject:@"skyler" forKey:@"u"];
        [message setObject:@"Brain Training Games iPad App - Reviewed and Recommended http://goo.gl/QkOrRt … #ipad via @IPadFamily #app #memory" forKey:@"m"];
        [message setObject:[self.class attributedStringWithMessage:
            [message objectForKey:@"m"]] forKey:@"attributedMessage"
        ];
        [message setObject:[NSDate date] forKey:@"__t"];
        
        [self.today addObject:message];
        
        message = [NSMutableDictionary dictionary];
        
        // Yesterday
        
        [message setObject:@"Hello World! #4" forKey:@"m"];
        [message setObject:[self.class attributedStringWithMessage:
            [message objectForKey:@"m"]] forKey:@"attributedMessage"
        ];
        [message setObject:[NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 25)] forKey:@"__t"];
        
        [self.yesterday addObject:message];
        
        message = [NSMutableDictionary dictionary];
        
        // Yesterday
        [message setObject:@"Hello World! #5" forKey:@"m"];
        [message setObject:[self.class attributedStringWithMessage:
            [message objectForKey:@"m"]] forKey:@"attributedMessage"
        ];
        [message setObject:[NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 32)] forKey:@"__t"];
        
        [self.yesterday addObject:message];
        
        message = [NSMutableDictionary dictionary];
        
        // Yesterday
        [message setObject:@"Hello World! #6" forKey:@"m"];
        [message setObject:[self.class attributedStringWithMessage:
            [message objectForKey:@"m"]] forKey:@"attributedMessage"
        ];
        [message setObject:[NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 47)] forKey:@"__t"];
        
        [self.yesterday addObject:message];
        
        message = [NSMutableDictionary dictionary];
        
        // Before Yesterday
        [message setObject:@"Hello World! #7" forKey:@"m"];
        [message setObject:[self.class attributedStringWithMessage:
            [message objectForKey:@"m"]] forKey:@"attributedMessage"
        ];
        [message setObject:[NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 56)] forKey:@"__t"];
        
        [self.beforeYesterday addObject:message];
        
        message = [NSMutableDictionary dictionary];
        
        // Before Yesterday
        [message setObject:@"Hello World! #8" forKey:@"m"];
        [message setObject:[self.class attributedStringWithMessage:
            [message objectForKey:@"m"]] forKey:@"attributedMessage"
        ];
        [message setObject:[NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 49)] forKey:@"__t"];
        
        [self.beforeYesterday addObject:message];
        
        [self.today sortUsingDescriptors:[NSArray arrayWithObject:
            [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
        ];
        [self.yesterday sortUsingDescriptors:[NSArray arrayWithObject:
            [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
        ];
        [self.beforeYesterday sortUsingDescriptors:[NSArray arrayWithObject:
            [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
        ];
#endif
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.allowsSelection = NO;
    
    if (self.viewControllerType == GVViewControllerTypeFeed)
    {
        self.title = NSLocalizedString(@"Timeline", nil);
        
        // left

        NSMutableArray * buttonsLeft = [NSMutableArray new];
        
        UIBarButtonItem * barButtonItemLeft = [[UIBarButtonItem alloc]
            initWithTitle:NSLocalizedString(@"Profile", nil)
            style:UIBarButtonItemStylePlain target:self
            action:@selector(goEditProfile:)
        ];
        
        [buttonsLeft addObject:barButtonItemLeft];
        
        [self.navigationItem setLeftBarButtonItems:buttonsLeft];
        
        // right

        NSMutableArray * buttons = [[NSMutableArray alloc] initWithCapacity:3];

        UIBarButtonItem * barButtonItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
            target:self action:@selector(goCompose:)
        ];
        [buttons addObject:barButtonItem];
        
        barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
            UIBarButtonSystemItemFixedSpace target:nil action:nil
        ];
        barButtonItem.width = 8.0f;
        [buttons addObject:barButtonItem];
        
        barButtonItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self
            action:@selector(goSearch:)
        ];
        [buttons addObject:barButtonItem];
        
        [self.navigationItem setRightBarButtonItems:buttons];
    }
    else if (self.viewControllerType == GVViewControllerTypeSearch)
    {
        self.title = NSLocalizedString(@"Search", nil);
        
        UISearchBar * searchBar = [[UISearchBar alloc] initWithFrame:
            CGRectMake(0, 0, 100, 40.0f)
        ];
        searchBar.delegate = self;
        self.tableView.tableHeaderView = searchBar;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (
        UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
        self.viewControllerType == GVViewControllerTypeSearch
        )
    {
        self.gestureRecognizer = [[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(handleTapBehind:)
        ];

        [self.gestureRecognizer setNumberOfTapsRequired:1];
        self.gestureRecognizer.cancelsTouchesInView = NO;
        [self.view.window addGestureRecognizer:self.gestureRecognizer];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (
        UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
        self.viewControllerType == GVViewControllerTypeSearch
        )
    {
        [self.view.window removeGestureRecognizer:self.gestureRecognizer];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

#if 0
- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    NSInteger ret = 0;
    
    for (NSDictionary * message in self.messages)
    {
        NSDate * t = [message objectForKey:@"__t"];
        
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:t];
        
        switch (section)
        {
            case 0:
            {
                if (timeInterval <= 60 * 60 * 24)
                {
                    NSLog(@"timeInterval = %.1f:%.1f", timeInterval, 60.0f * 60.0f * 24.0f);
                    ret++;
                }
            }
            break;
            case 1:
            {
                if (timeInterval > 60 * 60 * 24 && timeInterval <= 60 * 60 * 48)
                {
                    NSLog(@"timeInterval = %.1f:%.1f", timeInterval, 60.0f * 60.0f * 48.0f);
                    ret++;
                }
            }
            break;
            case 2:
            {
                if (timeInterval > 60 * 60 * 48)
                {
                    NSLog(@"timeInterval = %.1f:%.1f", timeInterval, 60.0f * 60.0f * 48.0f);
                    ret++;
                }
            }
            break;
            default:
            break;
        }
    }
    
    return ret;
}
#endif

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (UIView *)tableView:(UITableView *)tableView
    viewForHeaderInSection:(NSInteger)section
{
    GVTimelineTableHeaderView * headerView = [[GVTimelineTableHeaderView
        alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)
    ];

    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(14.0f, 2, tableView.bounds.size.width, 30)];
    label.text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    label.textColor = [UIColor colorWithRed:
            0.57f green:0.57f blue:0.57f alpha:1.0f
        ];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Droid Sans" size:14.0f];

    [headerView addSubview:label];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForHeaderInSection:(NSInteger)section
{
    return 36.0f;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return self.today.count;
    }
    else if (section == 1)
    {
        return self.yesterday.count;
    }
    else if (section == 2)
    {
        return self.beforeYesterday.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GVTimelineTableViewCell";
    GVTimelineTableViewCell *cell = [tableView
        dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath
    ];
    
    cell.delegate = self;
    
    NSDictionary * message = nil;

    if (indexPath.section == 0)
    {
        message = [self.today objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 1)
    {
        message = [self.yesterday objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 2)
    {        
        message = [self.beforeYesterday objectAtIndex:indexPath.row];
    }
    
    NSString * u = [message objectForKey:@"u"];
    
    NSDictionary * profile = [[GVProfileCache sharedInstance]
        profile:u
    ];
    
    NSAttributedString * attributedMessage = [message
        objectForKey:@"attributedMessage"
    ];

    NSString * f = [profile objectForKey:@"f"];
    
    NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:
        [message objectForKey:@"__t"]
    ];

    BOOL isSecs = NO;
    BOOL isMins = NO;
    BOOL isHours = NO;
    BOOL isExpired = NO;
    
    NSTimeInterval time = t;
    
    if (time > 60 * 60 * 72)
    {
        isExpired = YES;
    }
    else if (time > 60 * 60)
    {
        isHours = true;
        
        time = time / 60 / 60;
    }
    else if (time > 60)
    {
        isMins = YES;
        
        time = time / 60;
    }
    else
    {
        isSecs = YES;
    }

    NSString * p = [profile objectForKey:@"p"];

    [cell.avatarImageView setImageWithURL:
        [NSURL URLWithString:p] placeholderImage:[UIImage imageNamed:@"Avatar"]
    ];
    
    cell.avatarImageView.layer.masksToBounds = YES;
    cell.avatarImageView.layer.cornerRadius =
        cell.avatarImageView.frame.size.height / 2.0f
    ;
    [cell.self.avatarButton addTarget:self action:@selector(avatarTouched:)
        forControlEvents:UIControlEventTouchUpInside
    ];
#ifndef max
#define max(a,b) \
({ __typeof__ (a) _a = (a); \
__typeof__ (b) _b = (b); \
_a > _b ? _a : _b; })
#endif

    BOOL verified = [[message objectForKey:@"__v"] boolValue];

    cell.timeLabel.text = [NSString
        stringWithFormat:@"%.1f %@ ago via %@%@",
        max(1, time), isSecs ? @"seconds" :
        (isMins ? @"minutes" : @"hours"), ((f && f.length) ? f : u),
        verified ? @" √" : @""
    ];
    cell.messageTextView.delegate = self;
    cell.messageTextView.attributedText = attributedMessage;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return NSLocalizedString(@"Today", nil);
    }
    else if (section == 1)
    {
        return NSLocalizedString(@"Yesterday", nil);
    }
    else if (section == 2)
    {
        return NSLocalizedString(@"Before Yesterday", nil);
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)aTableView  
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * message = nil;

    if (indexPath.section == 0)
    {
        message = [self.today objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 1)
    {
        message = [self.yesterday objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 2)
    {        
        message = [self.beforeYesterday objectAtIndex:indexPath.row];
    }
    
    CGSize constraintSize = CGSizeMake(
        self.tableView.frame.size.width - (65.0f /* actually 65.0f */), MAXFLOAT
    );
    
    UIFont * cellFont = [UIFont fontWithName:@"Droid Sans" size:14.0f];
    
    CGSize labelSize = CGSizeZero;
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
    {
        labelSize = [[[message objectForKey:@"attributedMessage"] string]
            sizeWithFont:cellFont constrainedToSize:constraintSize
            lineBreakMode:NSLineBreakByCharWrapping
        ];
    }
    else
    {
        labelSize = [[message objectForKey:@"attributedMessage"]
            boundingRectWithSize:constraintSize options:
            NSLineBreakByCharWrapping | NSStringDrawingUsesLineFragmentOrigin context:nil
        ].size;
    }
    
    return labelSize.height + 48.0f;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - GVMessageTextViewDelegate


- (void)textView:(UITextView *)aTextView
    clickedOnLink:(NSString *)aLink
{
    if (
        [aLink rangeOfString:@"pbs.twimg.com" options:
        NSCaseInsensitiveSearch].location != NSNotFound ||
        [aLink rangeOfString:@".jpg" options:
        NSCaseInsensitiveSearch].location != NSNotFound ||
        [aLink rangeOfString:@".jpeg" options:
        NSCaseInsensitiveSearch].location != NSNotFound ||
        [aLink rangeOfString:@".png" options:
        NSCaseInsensitiveSearch].location != NSNotFound ||
        [aLink rangeOfString:@".gif" options:
        NSCaseInsensitiveSearch].location != NSNotFound
        )
    {
        IDMPhoto * photo = [[IDMPhoto alloc] initWithURL:[NSURL
            URLWithString:aLink]
        ];
        
        if (photo)
        {
            IDMPhotoBrowser * browser = [[IDMPhotoBrowser alloc] initWithPhotos:
                [NSArray arrayWithObject:photo] animatedFromView:self.tableView
            ];

            [self presentViewController:browser animated:YES completion:nil];
        }
    }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:aLink]];
    }
}

- (void)textView:(UITextView *)aTextView clickedOnUsername:(NSString *)aUsername
{
    NSLog(@"clickedOnUsername = %@", aUsername);
    
    GVTimelineTableViewController * timelineTableViewController2 = [[
        GVTimelineTableViewController alloc] initWithStyle:UITableViewStylePlain
        viewControllerType:GVViewControllerTypeSearch
    ];
    
    NSString * username = [aUsername
        stringByReplacingOccurrencesOfString:@" " withString:@""
    ];
    username = [username
        stringByReplacingOccurrencesOfString:@"@" withString:@""
    ];
    
    [timelineTableViewController2 searchUsername:username];

    [self.navigationController
        pushViewController:timelineTableViewController2 animated:YES
    ];
}

- (void)textView:(UITextView *)aTextView clickedOnHashtag:(NSString *)aHashtag
{
    NSLog(@"clickedOnHashtag = %@", aHashtag);
    
    GVTimelineTableViewController * timelineTableViewController2 = [[
        GVTimelineTableViewController alloc] initWithStyle:UITableViewStylePlain
        viewControllerType:GVViewControllerTypeSearch
    ];
    
    NSString * hashtag = [aHashtag
        stringByReplacingOccurrencesOfString:@" " withString:@""
    ];
    hashtag = [hashtag
        stringByReplacingOccurrencesOfString:@"#" withString:@""
    ];
    
    [timelineTableViewController2 searchHashtag:hashtag];

    [self.navigationController
        pushViewController:timelineTableViewController2 animated:YES
    ];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == self.composeViewController.sheetView.textView)
    {
        NSString * message = self.composeViewController.sheetView.textView.text;
        
        if (message.length)
        {
            NSArray * arrString = [message componentsSeparatedByString:@" "];

            BOOL shorten = NO;
            
            for (NSString * word in arrString)
            {
                if (
                    ([word rangeOfString:@"http://"].location != NSNotFound  ||
                    [word rangeOfString:@"https://"].location != NSNotFound) &&
                    [word rangeOfString:@"goo.gl"].location == NSNotFound &&
                    [word rangeOfString:@"grp.yt"].location == NSNotFound &&
                    word.length > 22)
                {
                    shorten = YES;
                    break;
                }
            }
            
            /**
             * Make sure the last character is a space.
             */
            if (
                [message rangeOfString:@" " options:NSCaseInsensitiveSearch
                range:NSMakeRange(message.length - 1, 1)].location != NSNotFound
                )
            {
                shorten = YES;
            }
            else
            {
                shorten = NO;
            }
            
            if (shorten)
            {
                NSLog(@"shorten");
                
                [self shortenComposeMessage];
            }
        }
    }
}

#pragma mark -

- (void)goSearch:(id)sender
{
    GVAppDelegate * delegate = [UIApplication sharedApplication].delegate;
    
    [delegate goSearch:sender];
}

- (void)goCompose:(id)sender
{
#if 1
    GVComposeViewController * composeViewController = [GVComposeViewController
        new
    ];
    
    UINavigationController * navigationController = [[UINavigationController
        alloc] initWithRootViewController:composeViewController
    ];
    
    navigationController.navigationBar.translucent = NO;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        navigationController.navigationBar.tintColor = [UIColor purpleColor];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        // ...
    }
    else
    {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        CGPoint center;
        
         center = CGPointMake(
            SCREEN_WIDTH / 2.0f, SCREEN_HEIGHT / 2.0f
        );
        
        [self presentViewController:
            navigationController animated:YES completion:nil
        ];
        
        navigationController.view.superview.frame = CGRectMake(
            navigationController.view.superview.frame.origin.x,
            navigationController.view.superview.frame.origin.y,
            navigationController.view.superview.frame.size.width, 320
        );
    }
    else
    {
        [self presentViewController:
            navigationController animated:YES completion:nil
        ];
    }
#else
    self.composeViewController = [[REComposeViewController
        alloc] initWithTextViewDelegate:self
    ];
    self.composeViewController.title = NSLocalizedString(@"Compose", nil);
    self.composeViewController.hasAttachment = NO;
    self.composeViewController.delegate = self;
    self.composeViewController.text = @"";
    [self.composeViewController presentFromRootViewController];
#endif
}

- (void)goEditProfile:(id)sender
{
    GVAppDelegate * delegate = [UIApplication sharedApplication].delegate;
    
    [delegate goEditProfile:sender];
}

- (void)avatarTouched:(id)sender
{
    UITableViewCell * tableViewCell = (UITableViewCell *)[[[sender
        superview] superview] superview
    ];
    
    if (![tableViewCell isKindOfClass:GVTimelineTableViewCell.class])
    {
        tableViewCell = (UITableViewCell *)[[[[sender superview]
            superview] superview] superview
        ];
    }
    
    NSParameterAssert(tableViewCell != nil);
    NSParameterAssert([tableViewCell isKindOfClass:GVTimelineTableViewCell.class]);
    
    NSIndexPath * indexPath = [self.tableView indexPathForCell:
        tableViewCell
    ];

    NSLog(@"indexPath = %@", indexPath);
    
    NSDictionary * message = nil;

    if (indexPath.section == 0)
    {
        message = [self.today objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 1)
    {
        message = [self.yesterday objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == 2)
    {        
        message = [self.beforeYesterday objectAtIndex:indexPath.row];
    }
    
    GVProfileViewController * profileViewController = [[GVProfileViewController
        alloc] initWithStyle:UITableViewStylePlain
    ];
    
    NSString * u = [message objectForKey:@"u"];
    
    profileViewController.username = u;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self.navigationController pushViewController:profileViewController
            animated:YES
        ];
    }
    else
    {
        if (self.profilePopoverController && [self.profilePopoverController isPopoverVisible])
        {
            [self.profilePopoverController dismissPopoverAnimated:YES];
        }
        else
        {
            UINavigationController * navigationController = [[UINavigationController
                alloc] initWithRootViewController:profileViewController
            ];
    
            self.profilePopoverController = [[UIPopoverController alloc]
                initWithContentViewController:navigationController
            ];
            
			self.profilePopoverController.popoverContentSize =
				CGSizeMake(320.0, 340.0)
			;
            
            [self.profilePopoverController 
                presentPopoverFromRect:[sender frame]
                inView:[sender superview]
                permittedArrowDirections:UIPopoverArrowDirectionAny
                animated:YES
            ];
        }
    }
}

#pragma -

- (void)searchUsername:(NSString *)aUsername
{
    NSString * keyword = aUsername;
    
    NSMutableString * query = [NSMutableString string];

    [query appendFormat:@"u=%@", keyword];

    NSLog(@"Searching for %@.", query);

    self.searchTransactionId = [self search:query clearCurrent:YES];
}

- (void)searchHashtag:(NSString *)aHashtag
{
    NSString * keyword = aHashtag;
    
    NSMutableString * query = [NSMutableString string];

    [query appendFormat:@"%@=%@", keyword, keyword];

    NSLog(@"Searching for %@.", query);

    self.searchTransactionId = [self search:query clearCurrent:YES];
}

- (NSInteger)search:(NSString *)aQuery clearCurrent:(BOOL)flag
{
    if (flag)
    {
        [self.today removeAllObjects];
        [self.yesterday removeAllObjects];
        [self.beforeYesterday removeAllObjects];
    
        [self.tableView reloadData];
    }

    return [[GVStack sharedInstance] find:aQuery];
}

#pragma mark -

+ (NSAttributedString *)attributedStringWithMessage:(NSString *)aMessage
{
    // Building up our attributed string
    NSMutableAttributedString * attributedStatusString = [[
        NSMutableAttributedString alloc] initWithString:aMessage
    ];
    
    // Defining our paragraph style for the tweet text. Starting with the shadow to make the text
    // appear inset against the gray background.
    NSShadow * textShadow = [[NSShadow alloc] init];
    [textShadow setShadowColor:[UIColor colorWithWhite:1.0f alpha:0.8f]];
    [textShadow setShadowBlurRadius:0];
    [textShadow setShadowOffset:CGSizeMake(0, -1)];
                             
    NSMutableParagraphStyle * paragraphStyle = [[NSParagraphStyle
        defaultParagraphStyle] mutableCopy
    ];
    [paragraphStyle setMinimumLineHeight:22];
    [paragraphStyle setMaximumLineHeight:22];
    [paragraphStyle setParagraphSpacing:0];
    [paragraphStyle setParagraphSpacingBefore:0];
    [paragraphStyle setAlignment:NSTextAlignmentNatural];
    [paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];

    // Our initial set of attributes that are applied to the full string length
    NSDictionary * fullAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [UIColor colorWithHue:.53 saturation:.13 brightness:0.26f alpha:1.0f],
        NSForegroundColorAttributeName, textShadow, NSShadowAttributeName,
        [NSNumber numberWithFloat:0.0], NSKernAttributeName,
        [NSNumber numberWithInt:0], NSLigatureAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName,
        [UIFont fontWithName:@"Droid Sans" size:14], NSFontAttributeName, nil
    ];
    
    [attributedStatusString addAttributes:fullAttributes
        range:NSMakeRange(0, [aMessage length])
    ];
    
    // Generate arrays of our interesting items. Links, usernames, hashtags.
    NSArray *linkMatches = [self.class scanStringForLinks:aMessage];
    NSArray *usernameMatches = [self.class scanStringForUsernames:aMessage];
    NSArray *hashtagMatches = [self.class scanStringForHashtags:aMessage];
    
    // Iterate across the string matches from our regular expressions, find the range
    // of each match, add new attributes to that range	
    for (NSString *linkMatchedString in linkMatches) {
        NSRange range = [aMessage rangeOfString:linkMatchedString];
        if( range.location != NSNotFound ) {
            // Add custom attribute of LinkMatch to indicate where our URLs are found. Could be blue
            // or any other color.
            NSDictionary *linkAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      [UIColor grayColor], NSForegroundColorAttributeName,
                                      [UIFont fontWithName:@"Droid Sans" size:14], NSFontAttributeName,
                                      linkMatchedString, @"LinkMatch",
                                      nil];
            [attributedStatusString addAttributes:linkAttr range:range];
        }
    }

    for (NSString *usernameMatchedString in usernameMatches) {
        NSRange range = [aMessage rangeOfString:usernameMatchedString];
        if( range.location != NSNotFound ) {
            // Add custom attribute of UsernameMatch to indicate where our usernames are found
            NSDictionary *linkAttr2 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       [UIColor darkGrayColor], NSForegroundColorAttributeName,
                                       [UIFont fontWithName:@"Droid Sans" size:14], NSFontAttributeName,
                                       usernameMatchedString, @"UsernameMatch",
                                       nil];
            [attributedStatusString addAttributes:linkAttr2 range:range];
        }
    }
    
    for (NSString *hashtagMatchedString in hashtagMatches) {
        NSRange range = [aMessage rangeOfString:hashtagMatchedString];
        if( range.location != NSNotFound ) {
            // Add custom attribute of HashtagMatch to indicate where our hashtags are found
            NSDictionary *linkAttr3 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      [UIColor grayColor], NSForegroundColorAttributeName,
                                      [UIFont fontWithName:@"Droid Sans" size:14], NSFontAttributeName,
                                      hashtagMatchedString, @"HashtagMatch",
                                      nil];
            [attributedStatusString addAttributes:linkAttr3 range:range];
        }
    }
    
// breaks links
//    [attributedStatusString.mutableString
//        replaceOccurrencesOfString:@"http://" withString:@""
//        options:NSCaseInsensitiveSearch range:
//        NSMakeRange(0, attributedStatusString.string.length)
//    ];
//    [attributedStatusString.mutableString
//        replaceOccurrencesOfString:@"https://" withString:@""
//        options:NSCaseInsensitiveSearch range:
//        NSMakeRange(0, attributedStatusString.string.length)
//    ];
    
    return attributedStatusString;
}

+ (NSArray *)scanStringForLinks:(NSString *)string
{
	return [string componentsMatchedByRegex:
        @"\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))"
    ];
}

+ (NSArray *)scanStringForUsernames:(NSString *)string
{
	return [string componentsMatchedByRegex:@"@{1}([-A-Za-z0-9_]{2,})"];
}

+ (NSArray *)scanStringForHashtags:(NSString *)string
{
	return [string componentsMatchedByRegex:@"#{1}([-A-Za-z0-9_]{2,})"];
}

#pragma mark -

- (void)didFindMessageNotification:(NSNotification *)aNotification
{
    NSMutableDictionary * message = [aNotification.object mutableCopy];
    
    NSString * username = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"username"
    ];
    //NSLog(@"didFindMessageNotification = %@", message);
    
    NSInteger transactionId = [[message objectForKey:@"transaction_id"] intValue];
    NSString * u = [message objectForKey:@"u"];
    
    if (self.viewControllerType == GVViewControllerTypeSearch)
    {
        if (self.searchTransactionId == transactionId)
        {
            /**
             * If we do not have a profile for this user perform
             * a lookup on it.
             */
            NSDictionary * profile = [[GVProfileCache sharedInstance]
                profile:u
            ];
    
            if (!profile || profile.count == 0)
            {
                NSString * query = [NSString
                    stringWithFormat:@"u=%@", u
                ];
                
                [[GVStack sharedInstance] find:query];
            }
        }
        else
        /**
         * Make sure the transaction id belongs to this controller.
         */
        {
            return;
        }
    }
    else if (self.viewControllerType == GVViewControllerTypeFeed)
    {
        /**
         * Make sure they are in our subscriptions.
         */
        if (![[GVStack sharedInstance].subscriptions objectForKey:u])
        {
            return;
        }
        
    }
    
    NSString * m = [message objectForKey:@"m"];
    NSDate * t = [message objectForKey:@"__t"];

    [message setObject:[self.class attributedStringWithMessage:m]
        forKey:@"attributedMessage"
    ];

    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:t];

    if (timeInterval <= 60 * 60 * 24)
    {
        //NSLog(@"timeInterval = %.1f:%.1f", timeInterval, 60.0f * 60.0f * 24.0f);
        
        NSInteger rowIndex = 0;
        
        for (NSDictionary * dict in self.today)
        {
            NSString * u2 = [dict objectForKey:@"u"];
            NSString * m2 = [dict objectForKey:@"m"];
            
            if ([u isEqualToString:u2] && [m isEqualToString:m2])
            {
                // Update the existing message.
                
                [self.today replaceObjectAtIndex:rowIndex withObject:message];
                
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:
                    [NSArray arrayWithObjects:
                    [NSIndexPath indexPathForRow:rowIndex
                    inSection:0], nil] withRowAnimation:
                    UITableViewRowAnimationNone
                ];
                [self.tableView endUpdates];
        
                return;
            }
            
            rowIndex++;
        }
    
    
    if (
        [[message objectForKey:@"m"] rangeOfString:
        [NSString stringWithFormat:@"@%@", username]].location != NSNotFound
        )
    {
        UILocalNotification * alert = [[UILocalNotification alloc] init];
        
        if (alert)
        {
            NSString * alertBody = [NSString stringWithFormat:
                @" %@ mentioned you",
                [NSString stringWithFormat:@"@%@", [message objectForKey:@"u"]]
            ];
            alert.alertBody = alertBody;

            [[UIApplication sharedApplication]
                presentLocalNotificationNow:alert
            ];
        }
    }
    
        [self.today addObject:message];
        [self.today sortUsingDescriptors:[NSArray arrayWithObject:
            [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
        ];
        
        NSInteger index = [self.today indexOfObject:message];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:
            [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:index
            inSection:0], nil] withRowAnimation:
            UITableViewRowAnimationAutomatic
        ];
        [self.tableView endUpdates];
    }
    else if (timeInterval > 60 * 60 * 24 && timeInterval <= 60 * 60 * 48)
    {
        //NSLog(@"timeInterval = %.1f:%.1f", timeInterval, 60.0f * 60.0f * 48.0f);
        
        NSInteger rowIndex = 0;
        
        for (NSDictionary * dict in self.yesterday)
        {
            NSString * u2 = [dict objectForKey:@"u"];
            NSString * m2 = [dict objectForKey:@"m"];
            
            if ([u isEqualToString:u2] && [m isEqualToString:m2])
            {
                // Update the existing message.
                
                [self.yesterday replaceObjectAtIndex:rowIndex withObject:message];
                
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:
                    [NSArray arrayWithObjects:
                    [NSIndexPath indexPathForRow:rowIndex
                    inSection:1], nil] withRowAnimation:
                    UITableViewRowAnimationNone
                ];
                [self.tableView endUpdates];
                
                return;
            }
            
            rowIndex++;
        }
        
        [self.yesterday addObject:message];
        [self.yesterday sortUsingDescriptors:[NSArray arrayWithObject:
            [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
        ];
        
        NSInteger index = [self.yesterday indexOfObject:message];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:
            [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:index
            inSection:1], nil] withRowAnimation:
            UITableViewRowAnimationAutomatic
        ];
        [self.tableView endUpdates];
    }
    else if (timeInterval > 60 * 60 * 48)
    {
        //NSLog(@"timeInterval = %.1f:%.1f", timeInterval, 60.0f * 60.0f * 48.0f);
        
        NSInteger rowIndex = 0;
        
        for (NSDictionary * dict in self.beforeYesterday)
        {
            NSString * u2 = [dict objectForKey:@"u"];
            NSString * m2 = [dict objectForKey:@"m"];
            
            if ([u isEqualToString:u2] && [m isEqualToString:m2])
            {
                // Update the existing message.
                
                [self.beforeYesterday replaceObjectAtIndex:rowIndex withObject:message];
                
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:
                    [NSArray arrayWithObjects:
                    [NSIndexPath indexPathForRow:rowIndex
                    inSection:2], nil] withRowAnimation:
                    UITableViewRowAnimationNone
                ];
                [self.tableView endUpdates];
                
                return;
            }
            
            rowIndex++;
        }
        
        [self.beforeYesterday addObject:message];
        [self.beforeYesterday sortUsingDescriptors:[NSArray arrayWithObject:
            [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
        ];
        
        NSInteger index = [self.beforeYesterday indexOfObject:message];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:
            [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:index
            inSection:2], nil] withRowAnimation:
            UITableViewRowAnimationAutomatic
        ];
        [self.tableView endUpdates];
    }
}

- (void)didFindProfileNotification:(NSNotification *)aNotification
{
    NSDictionary * dict = aNotification.object;
    
    //NSLog(@"didFindProfileNotification = %@", dict);
    
    NSString * u = [dict objectForKey:@"u"];

    NSString * username = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"username"
    ];
    
    // Do not sync our profile here, it's done in app delegate.
    if (u && ![u isEqualToString:username])
    {
        NSDictionary * profile = [[GVProfileCache sharedInstance]
            profile:u
        ];
        
        if (profile && profile.count)
        {
            NSDate * expires1 = [dict objectForKey:@"__t"];
            NSDate * expires2 = [profile objectForKey:@"__t"];

            NSTimeInterval lifetime1 = [[NSDate date]
                timeIntervalSinceDate:expires1
            ];
            
            NSTimeInterval lifetime2 = [[NSDate date]
                timeIntervalSinceDate:expires2
            ];

            if (lifetime1 < lifetime2)
            {
                [[GVProfileCache sharedInstance] setProfile:dict username:u];
                
                [self reloadRowsWithU:u];
            }
        }
        else
        {
            [[GVProfileCache sharedInstance] setProfile:dict username:u];
                
            [self reloadRowsWithU:u];
        }
    }
}

- (void)reloadRowsWithU:(NSString *)u
{
    [self.tableView beginUpdates];
    
    NSInteger rowIndex = 0;
    
    for (NSDictionary * message in self.today)
    {
        if ([[message objectForKey:@"u"] isEqualToString:u])
        {
            [self.tableView reloadRowsAtIndexPaths:
                [NSArray arrayWithObjects:
                [NSIndexPath indexPathForRow:rowIndex inSection:0],
                nil] withRowAnimation:UITableViewRowAnimationNone
            ];
        }
        
        rowIndex++;
    }
    
    rowIndex = 0;
    
    for (NSDictionary * message in self.yesterday)
    {
        if ([[message objectForKey:@"u"] isEqualToString:u])
        {
            [self.tableView reloadRowsAtIndexPaths:
                [NSArray arrayWithObjects:
                [NSIndexPath indexPathForRow:rowIndex inSection:1],
                nil] withRowAnimation:UITableViewRowAnimationNone
            ];
        }
        
        rowIndex++;
    }
    
    rowIndex = 0;
    
    for (NSDictionary * message in self.beforeYesterday)
    {
        if ([[message objectForKey:@"u"] isEqualToString:u])
        {
            [self.tableView reloadRowsAtIndexPaths:
                [NSArray arrayWithObjects:
                [NSIndexPath indexPathForRow:rowIndex inSection:2],
                nil] withRowAnimation:UITableViewRowAnimationNone
            ];
        }
        
        rowIndex++;
    }
    
    [self.tableView endUpdates];
}

#pragma mark -

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBarCancelButtonClicked");
    
    [self.today removeAllObjects];
    [self.yesterday removeAllObjects];
    [self.beforeYesterday removeAllObjects];

    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    if (aSearchBar.text.length)
    {
        [aSearchBar resignFirstResponder];
        
        if ([aSearchBar.text rangeOfString:@"@"].location != NSNotFound)
        {
            NSString * query = [aSearchBar.text
                stringByReplacingOccurrencesOfString:@"@" withString:@""
            ];
            
            [self searchUsername:query];
        }
        else
        {
            NSString * query = [aSearchBar.text
                stringByReplacingOccurrencesOfString:@"#" withString:@""
            ];
            
            [self searchHashtag:query];
        }
    }
}

#pragma mark -
#pragma mark REComposeViewControllerDelegate

- (void)composeViewController:(REComposeViewController *)composeViewController
    didFinishWithResult:(REComposeResult)result
{
    [composeViewController dismissViewControllerAnimated:YES completion:nil];

    if (result == REComposeResultPosted)
    {
        NSString * message = composeViewController.text;
        
        [[GVStack sharedInstance] post:message];
        
        /**
         * Perform a lookup on ourselves to synchronize.
         */
         
        NSString * username = [[NSUserDefaults standardUserDefaults]
            objectForKey:@"username"
        ];
        
        NSString * query = [NSString stringWithFormat:@"u=%@", username];
        
        [[GVStack sharedInstance] performSelector:@selector(find:)
            withObject:query afterDelay:1.0f
        ];
    }
}

#pragma mark - Shorten

- (void)shortenComposeMessage
{
    /**
     * Test: I want this #watch from @omega http://goo.gl/9EAy5 http://195.154.205.140/mesIMG/imgStd/21509.jpg http://4.bp.blogspot.com/-DIszQN87fJ4/Ti1nzFf8eqI/AAAAAAAAQrs/XD5Jf_a18BI/s400/OMEGA%2BSeamaster%2BPlanet%2BOcean%2BLiquidmetal%2BTitanium%2BChrono%2B9300%2B15.JPG
     */
    NSMutableString * finalMessage = [NSMutableString string];
    
    NSMutableArray * unprocessedUrls = [NSMutableArray array];
    NSMutableDictionary * processedUrls = [NSMutableDictionary dictionary];
    
    NSString * message = self.composeViewController.sheetView.textView.text;

    NSArray * arrString = [message componentsSeparatedByString:@" "];

    for (__strong NSString * word in arrString)
    {
        if (
            ([word rangeOfString:@"http://"].location != NSNotFound ||
            [word rangeOfString:@"https://"].location != NSNotFound) &&
            [word rangeOfString:@"goo.gl"].location == NSNotFound &&
            [word rangeOfString:@"grp.yt"].location == NSNotFound
            )
        {
            word = [word
                stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding
            ];
            
            [unprocessedUrls addObject:word];
        }
    }

    for (NSString * urlStr in unprocessedUrls)
    {
#if 1
        NSURL * url = [NSURL URLWithString:@"http://grp.yt/"];
#else
        NSURL * url = [NSURL URLWithString:
            @"https://www.googleapis.com/urlshortener/v1/url"
        ];
#endif
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];

        NSString * body = [NSString
            stringWithFormat:@"{\"longUrl\":\"%@\"}", [urlStr
            stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
        ];

        NSData * data = [NSData dataWithBytes:body.UTF8String length:body.length];
        
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:data];

        [NSURLConnection sendAsynchronousRequest:request
                queue:[NSOperationQueue mainQueue]
                completionHandler:^(NSURLResponse * response,
                    NSData * data,
                    NSError * error)
        {
            if (error)
            {
                NSLog(@"error = %@", error.description);
                
                // :TODO: show error
            }
            else
            {
                NSDictionary * json = [NSJSONSerialization
                    JSONObjectWithData:data options:0 error:nil
                ];

                NSString * shortUrl = [json objectForKey:@"id"];
                
                if (shortUrl)
                {
                    [processedUrls setObject:shortUrl forKey:urlStr];
                }
                
                [unprocessedUrls removeObject:urlStr];
                
                if (unprocessedUrls.count == 0)
                {
                    for (__strong NSString * word in arrString)
                    {
                        if (finalMessage.length > 0)
                        {
                            [finalMessage appendString:@" "];
                        }
                        
                        if (
                            ([word rangeOfString:@"http://"].location != NSNotFound ||
                            [word rangeOfString:@"https://"].location != NSNotFound)
                            )
                        {
                            word = [word
                                stringByAddingPercentEscapesUsingEncoding:
                                NSUTF8StringEncoding
                            ];
                            
                            NSString * shortUrl = [processedUrls objectForKey:word];

                            if (shortUrl && shortUrl.length)
                            {
                                [finalMessage appendString:shortUrl];
                            }
                            else
                            {
                                [finalMessage appendString:word];
                            }
                        }
                        else
                        {
                            [finalMessage appendString:word];
                        }
                    }

                    self.composeViewController.sheetView.textView.text = finalMessage;

//                    self.charCountTextField.stringValue = [NSString
//                        stringWithFormat:@"%@%zu",
//                        self.messageTextField.stringValue.length < 141 ? @"" :
//                        @"-", self.messageTextField.stringValue.length
//                    ];
//                    
//                    [self.composeViewController.composeSheetView setEnabled:
//                        self.messageTextField.stringValue.length > 0 &&
//                        self.messageTextField.stringValue.length < 141
//                    ];
                }
            }
        }];
    }
}

#pragma mark - DAContextMenuCell delegate

- (void)contextMenuCellDidSelectMoreOption:(DAContextMenuCell *)cell
{
    NSLog(@"contextMenuCellDidSelectDeleteOption");
    
    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
        delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
        destructiveButtonTitle:NSLocalizedString(@"Report", nil)
        otherButtonTitles:NSLocalizedString(@"Republish", nil), nil
    ];
    
    objc_setAssociatedObject(
        actionSheet, "DAContextMenuCell", cell, OBJC_ASSOCIATION_RETAIN
    );
    
    actionSheet.delegate = self;
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet
    didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    id cell = objc_getAssociatedObject(actionSheet, "DAContextMenuCell");

    objc_removeAssociatedObjects(actionSheet);

    [cell performSelector:@selector(hideMenuOptionsView)];
    
    switch (buttonIndex)
    {
        case 0:
        {
            NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];

            NSDictionary * message = nil;
            
            if (indexPath.section == 0)
            {
                message = [self.today objectAtIndex:indexPath.row];
            }
            else if (indexPath.section == 1)
            {
                message = [self.yesterday objectAtIndex:indexPath.row];
            }
            else if (indexPath.section == 2)
            {
                message = [self.beforeYesterday objectAtIndex:indexPath.row];
            }
            
            NSURL * url = [NSURL URLWithString:@"http://grapevine.am/report/"];

            NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];

            NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
            NSString * date = [dateFormatter stringFromDate:[NSDate date]];

            NSString * body = [NSString
                stringWithFormat:@"{\"u\":\"%@\",\"m\":\"%@\",\"d\":\"%@\"}",
                [message objectForKey:@"u"], [message objectForKey:@"m"], date
            ];

            NSData * data = [NSData dataWithBytes:body.UTF8String length:body.length];
            
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:data];

            [NSURLConnection sendAsynchronousRequest:request
                    queue:[NSOperationQueue mainQueue]
                    completionHandler:^(NSURLResponse * response,
                        NSData * data,
                        NSError * error)
            {
                if (error)
                {
                    // ...
                }
                else
                {
                    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:
                        NSLocalizedString(@"Thank You", nil) message:
                        NSLocalizedString(@"The message has been reported.", nil)
                        delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil)
                        otherButtonTitles:nil, nil
                    ];
                    
                    [alertView show];
                }
            }];
        }
        break;
        case 1:
        {
            NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];

            NSDictionary * message = nil;
            
            if (indexPath.section == 0)
            {
                message = [self.today objectAtIndex:indexPath.row];
            }
            else if (indexPath.section == 1)
            {
                message = [self.yesterday objectAtIndex:indexPath.row];
            }
            else if (indexPath.section == 2)
            {
                message = [self.beforeYesterday objectAtIndex:indexPath.row];
            }
            
            NSString * m = [NSString stringWithFormat:
                @"RE @%@ %@", [message objectForKey:@"u"],
                [message objectForKey:@"m"]
            ];
            
            NSLog(@"Republishing m = %@", m);
            
            [[GVStack sharedInstance] post:m];
            
            NSString * username = [[NSUserDefaults standardUserDefaults]
                objectForKey:@"username"
            ];
            
            NSString * query = [NSString stringWithFormat:@"u=%@", username];
            
            [[GVStack sharedInstance] find:query];  
        }
        break;
        default:
        break;
    }
}

#pragma mark -

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [sender locationInView:nil];

        if (
            ![self.view pointInside:[self.view convertPoint:location
            fromView:self.view.window] withEvent:nil]
            ) 
        {
            [self dismissModalViewControllerAnimated:true];
        }
    }
}

#pragma mark -

- (void)removeExpired
{
    //[self.tableView beginUpdates];
    
    NSInteger rowIndex = 0;
    
    NSMutableIndexSet * indexSet = [NSMutableIndexSet indexSet];
    NSMutableArray * indexPaths = [NSMutableArray new];
    
    NSMutableArray * tomorrow = [NSMutableArray array];
    
    for (NSDictionary * message in self.today)
    {
        NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:
            [message objectForKey:@"__t"]
        ];
    
        NSTimeInterval time = t / 60.0f / 60.0f;
 
        if (time > 24.0f)
        {
            [indexSet addIndex:rowIndex];
            
            [indexPaths addObject:[NSIndexPath indexPathForRow:rowIndex
                inSection:0]
            ];
            [tomorrow addObject:message];
        }
        
        rowIndex++;
    }
    
    [self.today removeObjectsInArray:tomorrow];
    [self.yesterday addObjectsFromArray:tomorrow];
    
    rowIndex = 0;
    
    indexSet = [NSMutableIndexSet indexSet];
    indexPaths = [NSMutableArray new];
    
    NSMutableArray * beforeYesterday = [NSMutableArray array];
    
    for (NSDictionary * message in self.yesterday)
    {
        NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:
            [message objectForKey:@"__t"]
        ];
    
        NSTimeInterval time = t / 60.0f / 60.0f;
        
        if (time > 48.0f)
        {
            [indexSet addIndex:rowIndex];
            
            [indexPaths addObject:[NSIndexPath indexPathForRow:rowIndex
                inSection:1]
            ];
            [beforeYesterday addObject:message];
        }
        
        rowIndex++;
    }
    
    [self.yesterday removeObjectsInArray:beforeYesterday];
    [self.beforeYesterday addObjectsFromArray:beforeYesterday];
    
    // beforeYesterday
    
    rowIndex = 0;
    
    indexSet = [NSMutableIndexSet indexSet];
    indexPaths = [NSMutableArray new];
    
    for (NSDictionary * message in self.beforeYesterday)
    {
        NSTimeInterval _t = [[NSDate date] timeIntervalSinceDate:
            [message objectForKey:@"__t"]
        ];

        NSTimeInterval time = _t / 60.0f / 60.0f;

        if (time > 72)
        {
            NSLog(@"Removing expired message %i.", rowIndex);
            
            [indexSet addIndex:rowIndex];
            
            [indexPaths addObject:[NSIndexPath indexPathForRow:rowIndex
                inSection:2]
            ];
        }
        
        rowIndex++;
    }
    
//    [self.tableView deleteRowsAtIndexPaths:indexPaths
//        withRowAnimation:UITableViewRowAnimationAutomatic
//    ];
    
    [self.beforeYesterday removeObjectsAtIndexes:indexSet];
    
    [self.today sortUsingDescriptors:[NSArray arrayWithObject:
        [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
    ];
    [self.yesterday sortUsingDescriptors:[NSArray arrayWithObject:
        [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
    ];
    [self.beforeYesterday sortUsingDescriptors:[NSArray arrayWithObject:
        [NSSortDescriptor sortDescriptorWithKey:@"__t" ascending:NO]]
    ];

#if 1
    [self.tableView reloadData];
#else
    @try
    {
        [self.tableView reloadSections:
            [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]
            withRowAnimation:UITableViewRowAnimationAutomatic
        ];
    }
    @catch (NSException *exception)
    {
        NSLog(@"%s: %@", __FUNCTION__, exception);
    }
#endif
    //[self.tableView endUpdates];
}

- (void)updateTick
{
    [self.tableView beginUpdates];
    [self.tableView reloadData];
    [self.tableView endUpdates];
}

#pragma mark -

- (void)reset
{
    [self.today removeAllObjects];
    [self.yesterday removeAllObjects];
    [self.beforeYesterday removeAllObjects];
    [self.tableView reloadData];
}

- (void)unsubscribe:(NSString *)aUsername
{
    NSMutableArray * toRemove = [NSMutableArray new];
    
    NSMutableArray * indexPaths = [NSMutableArray new];
    
    NSUInteger index = 0;
    
    for (NSDictionary * message in self.today)
    {
        if ([[message objectForKey:@"u"] isEqualToString:aUsername])
        {
            [indexPaths addObject:
                [NSIndexPath indexPathForRow:index inSection:0]
            ];
            
            [toRemove addObject:message];
        }
        
        index++;
    }
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPaths
        withRowAnimation:UITableViewRowAnimationAutomatic
    ];
    [self.today removeObjectsInArray:toRemove];
    [self.tableView endUpdates];
    
    toRemove = [NSMutableArray new];
    
    indexPaths = [NSMutableArray new];
    
    index = 0;
    
    for (NSDictionary * message in self.yesterday)
    {
        if ([[message objectForKey:@"u"] isEqualToString:aUsername])
        {
            [indexPaths addObject:
                [NSIndexPath indexPathForRow:index inSection:1]
            ];
            
            [toRemove addObject:message];
        }
        
        index++;
    }
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPaths
        withRowAnimation:UITableViewRowAnimationAutomatic
    ];
    [self.yesterday removeObjectsInArray:toRemove];
    [self.tableView endUpdates];
    
    toRemove = [NSMutableArray new];
    
    indexPaths = [NSMutableArray new];
    
    index = 0;
    
    for (NSDictionary * message in self.beforeYesterday)
    {
        if ([[message objectForKey:@"u"] isEqualToString:aUsername])
        {
            [indexPaths addObject:
                [NSIndexPath indexPathForRow:index inSection:2]
            ];
            
            [toRemove addObject:message];
        }
        
        index++;
    }
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPaths
        withRowAnimation:UITableViewRowAnimationAutomatic
    ];
    [self.beforeYesterday removeObjectsInArray:toRemove];
    [self.tableView endUpdates];
}

@end
