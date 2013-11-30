//
//  GVSignInViewController.m
//  Grapevine
//
//  Created by Packet7, LLC. on 8/1/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "MBProgressHUD.h"
#import "SFHFKeychainUtils.h"

#import "NSData+Conversion.h"
#import "NSString+HMACSHA.h"

#import "GVRegisterViewController.h"
#import "GVSignInViewController.h"

@interface GVSignInViewController ()
@property (strong) UITextField * usernameTextField;
@property (strong) UITextField * passwordTextField;
@property (assign) BOOL signInEnabled;
@property (strong) MBProgressHUD * progressHUD;
@property (copy) NSString * username;
@property (copy) NSString * password;
@end

static NSString * kGVServiceName = @"GVServiceName";

@implementation GVSignInViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.signInEnabled = NO;
        [self.tableView registerClass:UITableViewCell.class
            forCellReuseIdentifier:@"GVSignInTableViewCell"
        ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didConnectNotification:)
            name:kGVDidConnectNotification object:nil
        ];
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didSignInNotification:)
            name:kGVDidSignInNotification object:nil
        ];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Grapevine", nil);
    
    self.username = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"username"
    ];
    
    if (self.username.length > 0)
    {
        NSError * err = 0;
        
        self.password = [SFHFKeychainUtils
            getPasswordForUsername:self.username andServiceName:kGVServiceName
            error:&err
        ];
        
        if (err)
        {
            NSLog(@"getPasswordForUsername failed, err = %@", err);
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (![GVStack sharedInstance].isConnected)
    {
        self.progressHUD = [[MBProgressHUD alloc] initWithView:
            self.navigationController.view
        ];
        self.progressHUD.labelText = NSLocalizedString(@"Connecting", nil);
        [self.view.window addSubview:self.progressHUD];
        [self.progressHUD show:YES];
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 2;
        case 1:
            return 1;
        case 2:
            return 1;
        default:
            break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"GVSignInTableViewCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:
        CellIdentifier forIndexPath:indexPath
    ];
    
    switch (indexPath.section)
    {
        case 0:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = NSLocalizedString(@"User Name", nil);
 
                    if (!self.usernameTextField)
                    {
                        self.usernameTextField = [self makeTextField:nil
                            placeholder:NSLocalizedString(@"alice", nil)
                            indexPath:indexPath secureTextEntry:NO
                        ];
                        self.usernameTextField.delegate = self;
                        self.usernameTextField.placeholder = NSLocalizedString(@"alice", nil);
                        [cell.contentView addSubview:self.usernameTextField];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self
                            selector:@selector(textFieldTextDidChangeNotification:)
                            name:UITextFieldTextDidChangeNotification 
                            object:self.usernameTextField
                        ];
                    }
                    
                    self.usernameTextField.text = self.username;
                    
                    self.usernameTextField.frame = CGRectMake(
                        122.0f, 13.0f,
                        cell.contentView.frame.size.width - 132.0f, 22.0f
                    );
                }
                break;
                case 1:
                {
                    cell.textLabel.text = NSLocalizedString(@"Password", nil);
                    
                    if (!self.passwordTextField)
                    {
                        self.passwordTextField = [self makeTextField:nil
                            placeholder:NSLocalizedString(@"Required", nil)
                            indexPath:indexPath secureTextEntry:YES
                        ];
                        self.passwordTextField.delegate = self;
                        self.passwordTextField.placeholder = NSLocalizedString(@"Required", nil);
                        [cell.contentView addSubview:self.passwordTextField];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self
                            selector:@selector(textFieldTextDidChangeNotification:)
                            name:UITextFieldTextDidChangeNotification 
                            object:self.passwordTextField
                        ];
                    }
                    
                    self.passwordTextField.frame = CGRectMake(
                        122.0f, 13.0f,
                        cell.contentView.frame.size.width - 132.0f, 22.0f
                    );
                    
                    self.passwordTextField.text = self.password;
                }
                break;
                default:
                break;
            }
        }
        break;
        case 1:
        {
            cell.textLabel.text = NSLocalizedString(@"Sign In", nil);
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = self.signInEnabled ?
                [UIColor blackColor] : [UIColor grayColor]
            ;
        }
        break;
        case 2:
        {
            cell.textLabel.text = NSLocalizedString(@"Create New Account", nil);
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
        }
        break;
        default:
            break;
    }
 
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
    if (indexPath.section == 1 && indexPath.row == 0)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [self signIn];
    }
    else if (indexPath.section == 2 && indexPath.row == 0)
    {
        GVRegisterViewController * detailViewController = [[
            GVRegisterViewController alloc] initWithStyle:
            UITableViewStyleGrouped
        ];

        [self.navigationController pushViewController:detailViewController
            animated:YES
        ];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
            return NO;
        case 1:
        {
            return self.signInEnabled;
        }
        case 2:
            return YES;
        default:
            break;
    }
    
    return YES;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    self.username = self.usernameTextField.text;
    self.password = self.passwordTextField.text;
    
    self.signInEnabled =
        self.username.length >= 5 && self.password.length >= 8
    ;
    
	return YES;
}	

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // ...
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField)
    {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField)
    {
        [self.usernameTextField becomeFirstResponder];
    }
    
    return false;
}

#pragma mark -

- (void)textFieldTextDidChangeNotification:(NSNotification *)aNotification
{
    self.username = self.usernameTextField.text;
    self.password = self.passwordTextField.text;
    
    self.signInEnabled =
        self.username.length >= 5 && self.password.length >= 8
    ;
    
    [self.tableView reloadRowsAtIndexPaths:
        [NSArray arrayWithObjects:
        [NSIndexPath indexPathForRow:0 inSection:1],
        nil] withRowAnimation:UITableViewRowAnimationNone
    ];
}

#pragma mark -

- (UITextField *)makeTextField:(NSString *)text
    placeholder:(NSString *)placeholder indexPath:(NSIndexPath *)indexPath
        secureTextEntry:(BOOL)secureTextEntry
{
    UITextField * textField = [[UITextField alloc] init];
    textField.secureTextEntry = secureTextEntry;
    textField.tag = 1000 + indexPath.row;
    textField.placeholder = placeholder;  
    textField.text = text;
    //textField.font = [UIFont fontWithName:@"Droid Sans" size:14.0f];
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
    textField.frame = CGRectMake(122.0f, 13.0f, 170.0f, 22.0f);
    return textField;  
}

#pragma mark -

- (void)signIn
{
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    self.title = NSLocalizedString(@"Signing In", nil);

    if (!self.progressHUD)
    {
        self.progressHUD = [[MBProgressHUD alloc] initWithView:
            self.navigationController.view
        ];
        self.progressHUD.labelText = NSLocalizedString(@"Signing In", nil);
        [self.view.window addSubview:self.progressHUD];
        [self.progressHUD show:YES];
    }
    
    [[GVStack sharedInstance] signIn:
        self.usernameTextField.text password:self.passwordTextField.text
    ];
}

#pragma mark -

- (void)didConnectNotification:(NSNotification *)aNotification
{
    if (self.username && self.password)
    {
        NSLog(@"Connected %@:%@", self.username, self.password);
        
        self.title = NSLocalizedString(@"Signing In", nil);

        self.progressHUD.labelText = NSLocalizedString(@"Signing In", nil);
    
        [[GVStack sharedInstance] signIn:
            self.username password:self.password
        ];
    }
    else
    {
        [self.progressHUD hide:YES];
        [self.progressHUD removeFromSuperview];
        self.progressHUD = nil;
    }
}

- (void)didSignInNotification:(NSNotification *)aNotification
{
    NSDictionary * dict  = aNotification.object;
    
    if ([[dict objectForKey:@"status"] intValue] == 0)
    {
        NSError * err = 0;
        
        [SFHFKeychainUtils storeUsername:self.username
            andPassword:self.password forServiceName:kGVServiceName
            updateExisting:YES error:&err
        ];
        
        if (err)
        {
            NSLog(@"storeUsername failed err = %@", err);
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:
            self.username forKey:@"username"
        ];
        
        NSMutableDictionary * preferences = [[[NSUserDefaults
            standardUserDefaults] objectForKey:self.username]
            mutableCopy
        ];
        
        if (!preferences)
        {
            [[NSUserDefaults standardUserDefaults] setObject:
                [NSMutableDictionary new] forKey:self.username
            ];
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize];

        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        NSLog(@"Sign in failed (%@).", [dict objectForKey:@"status"]);
        
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:
            NSLocalizedString(@"Error Signing In", nil) message:
            NSLocalizedString(@"The user name or password is incorrect.", nil)
            delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil)
            otherButtonTitles:nil, nil
        ];
        
        [alertView show];
        
        self.title = NSLocalizedString(@"Grapevine", nil);
        
        [self.usernameTextField becomeFirstResponder];
    }
    
    [self.progressHUD hide:YES];
    [self.progressHUD removeFromSuperview];
    self.progressHUD = nil;
}

@end
