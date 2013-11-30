//
//  GVEditProfileViewController.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/29/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "UIImageView+WebCache.h"

#import "GVAppDelegate.h"
#import "GVEditProfileTableViewCell.h"
#import "GVEditProfileViewController.h"

@interface GVEditProfileViewController ()
@property (strong) NSMutableDictionary * profile;
@property (strong) UIImageView * avatarImageView;
@property (strong) UITextField * fullnameTextField;
@property (strong) UITextField * locationTextField;
@property (strong) UITextField * photoTextField;
@property (strong) UITextField * webTextField;
@property (strong) UITextField * bioTextField;
@end

@implementation GVEditProfileViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:GVEditProfileTableViewCell.class
            forCellReuseIdentifier:@"EditProfileTableViewCell"
        ];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Profile", nil);
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:NSLocalizedString(@"Sign Out", nil)
        style:UIBarButtonItemStyleBordered target:self
        action:@selector(signOut:)
    ];

    NSString * username = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"username"
    ];
    
    NSDictionary * profile = [[GVProfileCache sharedInstance]
        profile:username
    ];

    self.profile = profile == nil ? [NSMutableDictionary new] : profile.mutableCopy;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString * username = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"username"
    ];
    
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
        profile:username
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITextField *)makeTextField:(NSString *)text
    placeholder:(NSString *)placeholder indexPath:(NSIndexPath *)indexPath
{
    UITextField * textField = [[UITextField alloc] init];
    textField.tag = 1000 + indexPath.row;
    textField.placeholder = placeholder;  
    textField.text = text;
    textField.font = [UIFont fontWithName:@"Droid Sans" size:14.0f];
    textField.returnKeyType = UIReturnKeyNext;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;  
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;  
    textField.adjustsFontSizeToFitWidth = NO;
    textField.delegate = self;
    textField.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight
    ;
    textField.textColor = [UIColor blackColor];
    [textField addTarget:self action:@selector(textFieldFinished:)
        forControlEvents:UIControlEventEditingDidEndOnExit
    ];
    textField.frame = CGRectMake(112, 13, 170, 22);
    return textField;  
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"EditProfileTableViewCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:
        CellIdentifier forIndexPath:indexPath
    ];
    
    cell.textLabel.font = [UIFont fontWithName:@"Droid Sans" size:12.0f];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Droid Sans" size:14.0f];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UITextField * textField = (UITextField *)[cell viewWithTag:1000 + indexPath.row];

    switch (indexPath.row)
    {
        case 0:
        {
            if (!textField)
            {
                textField = self.fullnameTextField = [self
                    makeTextField:nil placeholder:@""
                    indexPath:indexPath
                ];
                [cell addSubview:textField];
                
                //[textField becomeFirstResponder];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Fullname", nil);
            textField.text = [self.profile objectForKey:@"f"];
        }
        break;
        case 1:
        {
            if (!textField)
            {
                textField = self.locationTextField = [self
                    makeTextField:nil placeholder:@""
                    indexPath:indexPath
                ];
                [cell addSubview:textField];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Location", nil);
            textField.text = [self.profile objectForKey:@"l"];
        }
        break;
        case 2:
        {
            if (!textField)
            {
                textField = self.photoTextField = [self
                    makeTextField:nil placeholder:@"http://"
                    indexPath:indexPath
                ];
                [cell addSubview:textField];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Photo", nil);
            textField.text = [self.profile objectForKey:@"p"];
        }
        break;
        case 3:
        {
            if (!textField)
            {
                textField = self.webTextField = [self
                    makeTextField:nil placeholder:@"http://"
                    indexPath:indexPath
                ];
                [cell.contentView addSubview:textField];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Web", nil);
            textField.text = [self.profile objectForKey:@"w"];
        }
        break;
        case 4:
        {
            if (!textField)
            {
                textField = self.bioTextField = [self
                    makeTextField:nil placeholder:@""
                    indexPath:indexPath
                ];
                [cell.contentView addSubview:textField];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Bio", nil);
            textField.text = [self.profile objectForKey:@"b"];
        }
        break;
        default:
        break;
    }
    
    return cell;
}

//- (UITableViewCell *)tableView:(UITableView *)tableView
//    willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    
//    return cell;
//}

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
#pragma mark Editing text fields

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    NSLog(@"textFieldShouldEndEditing");
    
    if (textField == self.fullnameTextField)
    {
        if (self.fullnameTextField.text)
        {
            [self.profile setObject:self.fullnameTextField.text forKey:@"f"];
        }
    }
    
    if (textField == self.locationTextField)
    {
        if (self.locationTextField.text)
        {
            [self.profile setObject:self.locationTextField.text forKey:@"l"];
        }
    }
    
    if (textField == self.photoTextField)
    {
        if (self.photoTextField.text)
        {
            [self.profile setObject:self.photoTextField.text forKey:@"p"];
        }
    }
    
    if (textField == self.webTextField)
    {
        if (self.webTextField.text)
        {
            [self.profile setObject:self.webTextField.text forKey:@"w"];
        }
    }
    
    if (textField == self.bioTextField)
    {
        if (self.bioTextField.text)
        {
            [self.profile setObject:self.bioTextField.text forKey:@"b"];
        }
    }
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString * username = [userDefaults objectForKey:@"username"];
    
    NSDictionary * preferences = [userDefaults objectForKey:username];
    
    NSDictionary * profile = [preferences objectForKey:@"profile"];
    
    if (![self.profile isEqualToDictionary:profile])
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithTitle:NSLocalizedString(@"Publish", nil)
            style:UIBarButtonItemStyleDone target:self action:@selector(publish:)
        ];
    }
    
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"textFieldShouldEndEditing");
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.fullnameTextField)
    {
        [self.locationTextField becomeFirstResponder];
    }
    else if (textField == self.locationTextField)
    {
        [self.photoTextField becomeFirstResponder];
    }
    else if (textField == self.photoTextField)
    {
        [self.webTextField becomeFirstResponder];
    }
    else if (textField == self.webTextField)
    {
        [self.bioTextField becomeFirstResponder];
    }
    else if (textField == self.bioTextField)
    {
        [self.fullnameTextField becomeFirstResponder];
    }
    
    return false;
}

#pragma mark -

- (void)publish:(id)sender
{
    [sender setEnabled:NO];
    
    if (self.fullnameTextField.text)
    {
        [self.profile setObject:self.fullnameTextField.text forKey:@"f"];
    }

    if (self.locationTextField.text)
    {
        [self.profile setObject:self.locationTextField.text forKey:@"l"];
    }

    if (self.photoTextField.text)
    {
        [self.profile setObject:self.photoTextField.text forKey:@"p"];
    }

    if (self.webTextField.text)
    {
        [self.profile setObject:self.webTextField.text forKey:@"w"];
    }

    if (self.bioTextField.text)
    {
        [self.profile setObject:self.bioTextField.text forKey:@"b"];
    }
    
    if (self.photoTextField.text.length > 0)
    {
        if (
            [self.photoTextField.text rangeOfString:@"http" options:
            NSCaseInsensitiveSearch].location == NSNotFound
            )
        {
            return;
        }
    }
    
    if (self.webTextField.text.length > 0)
    {
        if (
            [self.webTextField.text rangeOfString:@"http" options:
            NSCaseInsensitiveSearch].location == NSNotFound
            )
        {
            return;
        }
    }
    
    NSLog(@":TODO:");
    
    [self performSelectorInBackground:@selector(updateProfile:)
        withObject:self.profile
    ];
}

- (void)cancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)signOut:(id)sender
{
    GVAppDelegate * delegate = (GVAppDelegate *)[UIApplication
        sharedApplication].delegate
    ;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self.navigationController performSelector:
            @selector(popViewControllerAnimated:) withObject:
            [NSNumber numberWithBool:YES] afterDelay:0.0f
        ];
    }
    else
    {
        [delegate.editProfilePopoverController performSelector:
            @selector(dismissPopoverAnimated:) withObject:
            [NSNumber numberWithBool:YES] afterDelay:0.0f
        ];
    }
    
    [delegate performSelector:@selector(signOut:) withObject:nil
        afterDelay:0.5f
    ];
}

#pragma mark -

- (void)updateProfile:(NSDictionary *)aProfile
{
    NSString * p = [aProfile objectForKey:@"p"];
    
    if (p.length > 0)
    {
        NSString * p2 = [self synchronousShorten:p];
        
        if (p2 && p2.length)
        {
            p = [self synchronousShorten:p];
            
            if (p)
            {
                [self.profile setObject:p forKey:@"p"];
            }
        }
    }
    
    NSString * w = [aProfile objectForKey:@"w"];
    
    if (w.length > 0)
    {
        NSString * w2 = [self synchronousShorten:w];
        
        if (w2 && w2.length)
        {
            w = w2;
            
            if (w)
            {
                [self.profile setObject:w forKey:@"w"];
            }
        }
    }
    
    // :TODO: [profile setObject:nil forKey:@"a"];
    // :TODO: [profile setObject:nil forKey:@"g"]
    
    dispatch_async(dispatch_get_main_queue(),^
    {
        if (p)
        {
            self.photoTextField.text = p;
            [self.avatarImageView setImageWithURL:[NSURL URLWithString:p]
                placeholderImage:[UIImage imageNamed:@"Avatar"]
            ];
        }
        
        if (w)
        {
            self.webTextField.text = w;
        }
        
        NSString * username = [[NSUserDefaults standardUserDefaults]
            objectForKey:@"username"
        ];
        
        NSMutableDictionary * preferences = [[[NSUserDefaults
            standardUserDefaults] objectForKey:username] mutableCopy
        ];
        
        if (!preferences)
        {
            preferences = [NSMutableDictionary new];
        }
        
        [preferences setObject:self.profile forKey:@"profile"];
        
        [[NSUserDefaults standardUserDefaults] setObject:preferences
            forKey:username
        ];
        
        [[NSUserDefaults standardUserDefaults] synchronize];

        [[GVProfileCache sharedInstance] setProfile:self.profile
            username:username
        ];
        
        [[GVStack sharedInstance] updateProfile];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            [self.navigationController performSelector:
                @selector(popViewControllerAnimated:) withObject:
                [NSNumber numberWithBool:YES] afterDelay:1.0f
            ];
        }
        else
        {
            GVAppDelegate * delegate = (GVAppDelegate *)[UIApplication
                sharedApplication].delegate
            ;
            
            [delegate.editProfilePopoverController performSelector:
                @selector(dismissPopoverAnimated:) withObject:
                [NSNumber numberWithBool:YES] afterDelay:1.0f
            ];
        }
    });
}

- (NSString *)synchronousShorten:(NSString *)aURL
{
#if 1
    NSURL * url = [NSURL URLWithString:
        @"http://grp.yt/"
    ];
#else
    NSURL * url = [NSURL URLWithString:
        @"https://www.googleapis.com/urlshortener/v1/url"
    ];
#endif
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];

    NSString * body = [NSString
        stringWithFormat:@"{\"longUrl\":\"%@\"}", [aURL
        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
    ];

    NSData * data = [NSData dataWithBytes:body.UTF8String length:body.length];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    
    NSURLResponse * response = nil;
    NSError * error = nil;
    
    NSData * responseData = [NSURLConnection sendSynchronousRequest:request
        returningResponse:&response error:&error
    ];

    if (error)
    {
        NSLog(@"error = %@", error.description);
        
        // :TODO: show error
    }
    else
    {
        NSDictionary * json = [NSJSONSerialization
            JSONObjectWithData:responseData options:0 error:nil
        ];

        return [json objectForKey:@"id"];
    }
    
    return nil;
}

@end
