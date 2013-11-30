//
//  GVProfileViewController.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/29/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "UIImageView+WebCache.h"

#import "GVAppDelegate.h"
#import "GVProfileTableViewCell.h"
#import "GVProfileViewController.h"
#import "GVTimelineTableViewController.h"

@interface GVProfileViewController ()
@property (strong) NSMutableArray * keys;
@property (strong) UIImageView * avatarImageView;
@property (strong) UIBarButtonItem * subscribeButtonItem;
@end

@implementation GVProfileViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.keys = [NSMutableArray new];
        
        [self.tableView registerClass:GVProfileTableViewCell.class
            forCellReuseIdentifier:@"ProfileTableViewCell"
        ];

        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.title = NSLocalizedString(@"Profile", nil);
    
    self.subscribeButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:NSLocalizedString(@"Subscribe", nil)
        style:UIBarButtonItemStylePlain target:self
        action:@selector(subscribe:)
    ];
    
    self.navigationItem.rightBarButtonItem = self.subscribeButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = [NSString stringWithFormat:@"@%@", self.username];
    
    CGRect frame = self.view.frame;
    
    #define AVATAR_OFFSET 16.0f
    
    self.avatarImageView = [[UIImageView alloc] initWithFrame:
        CGRectMake(frame.size.width / 2.0f - 96.0f / 2.0f, AVATAR_OFFSET, 96.0f, 96.0f)
    ];

    UIView * headerView = [[UIView alloc] initWithFrame:
        CGRectMake(0, 0, frame.size.width, 96.0f + (AVATAR_OFFSET + 8.0f))
    ];
    
    [headerView addSubview:self.avatarImageView];

    self.tableView.tableHeaderView = headerView;
    
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.layer.cornerRadius =
        self.avatarImageView.frame.size.height / 2.0f
    ;
    
    NSDictionary * profile = [[GVProfileCache sharedInstance]
        profile:self.username
    ];
    
    if (profile.count > 0)
    {
        NSString * p = [profile objectForKey:@"p"];
        
        [self.avatarImageView setImageWithURL:[NSURL URLWithString:p]
            placeholderImage:[UIImage imageNamed:@"Avatar"]
        ];
    }
    else
    {
        self.avatarImageView.image = [UIImage imageNamed:@"Avatar"];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSDictionary * profile = [[GVProfileCache sharedInstance]
        profile:self.username
    ];
    [self setup:profile];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return self.keys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"ProfileTableViewCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:
        CellIdentifier forIndexPath:indexPath
    ];
    
    NSDictionary * profile = [[GVProfileCache sharedInstance]
        profile:self.username
    ];
    
    NSString * key = [self.keys objectAtIndex:indexPath.row];
    NSString * value = [profile objectForKey:key];
    
    if ([key isEqualToString:@"b"])
    {
        key = NSLocalizedString(@"Bio:", nil);
    }
    else if ([key isEqualToString:@"f"])
    {
        key = NSLocalizedString(@"Fullname:", nil);
    }
    else if ([key isEqualToString:@"l"])
    {
        key = NSLocalizedString(@"Location:", nil);
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Droid Sans" size:12.0f];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Droid Sans" size:14.0f];
    
    cell.textLabel.text = key;
    cell.detailTextLabel.text = value;
    
    return cell;
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

#pragma mark -

- (void)setup:(NSDictionary *)aProfile
{
    NSLog(@"aProfile = %@", aProfile);
    
    if (aProfile.count > 0)
    {
        NSString * u = [aProfile objectForKey:@"u"];

        if ([[GVStack sharedInstance].subscriptions objectForKey:u])
        {
            self.subscribeButtonItem.title = NSLocalizedString(
                @"Unsubscribe", nil
            );
        }
        else
        {
            self.subscribeButtonItem.title = NSLocalizedString(
                @"Subscribe", nil
            );
        }
        
        NSInteger rowIndex = 0;
        
        for (NSString * key in aProfile)
        {
            if (
                [key isEqualToString:@"u"] ||
                [key isEqualToString:@"p"] ||
                [key isEqualToString:@"transaction_id"]
                )
            {
                continue;
            }
            
            id value = [aProfile objectForKey:key];
            
            if ([key isEqualToString:@"__v"])
            {
                if ([value boolValue])
                {
                    self.title = [NSString
                        stringWithFormat:@"@%@ √", self.username
                    ];
                }
                
                continue;
            }

            if (value && [value isKindOfClass:[NSString class]] && [value length])
            {
                [self.keys addObject:key];
                
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:
                    [NSArray arrayWithObjects:[NSIndexPath
                    indexPathForRow:rowIndex inSection:0], nil]
                    withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                
                rowIndex++;
            }
        }
    }
    else
    {
        // ...
    }
}

#pragma mark -

- (IBAction)subscribe:(id)sender
{
    NSString * u = self.username;
    
    NSLog(@"Subscribing to %@.", u);
    
    if (u && u.length)
    {
        GVAppDelegate * delegate = (GVAppDelegate *)[UIApplication sharedApplication].delegate;
        
        if ([[GVStack sharedInstance].subscriptions objectForKey:u])
        {
            [[GVStack sharedInstance] unsubscribe:u];
            
            [delegate.timelineTableViewController unsubscribe:u];
            
            self.subscribeButtonItem.title = NSLocalizedString(
                @"Subscribe", nil
            );
        }
        else
        {
            [[GVStack sharedInstance] subscribe:u];

            self.subscribeButtonItem.title = NSLocalizedString(
                @"Unsubscribe", nil
            );
        }
    }
}


@end
