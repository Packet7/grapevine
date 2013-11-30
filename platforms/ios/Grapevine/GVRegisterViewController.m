//
//  GVRegisterViewController.m
//  Grapevine
//
//  Created by Packet7, LLC. on 8/1/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "MBProgressHUD.h"

#import "GVRegisterViewController.h"

@interface GVRegisterViewController ()
@property (strong) UITextField * usernameTextField;
@property (strong) UITextField * password1TextField;
@property (strong) UITextField * password2TextField;
@property (strong) UITextField * secretTextField;
@property (assign) BOOL signUpEnabled;
@property (strong) NSURLConnection * urlConnection;
@property (strong) NSMutableData * responseData;
@property (strong) MBProgressHUD * progressHUD;
@end

@implementation GVRegisterViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:UITableViewCell.class
            forCellReuseIdentifier:@"GVRegisterTableViewCell"
        ];
        self.signUpEnabled = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Sign Up", nil);
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
            return 3;
        case 1:
            return 1;
        case 2:
            return 1;
        default:
        break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GVRegisterTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
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
                        [cell.contentView addSubview:self.usernameTextField];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self
                            selector:@selector(textFieldTextDidChangeNotification:)
                            name:UITextFieldTextDidChangeNotification 
                            object:self.usernameTextField
                        ];
                    }
                    
                    self.usernameTextField.frame = CGRectMake(
                        122.0f, 13.0f,
                        cell.contentView.frame.size.width - 132.0f, 22.0f
                    );

                }
                break;
                case 1:
                {
                    cell.textLabel.text = NSLocalizedString(@"Password", nil);
                    
                    if (!self.password1TextField)
                    {
                        self.password1TextField = [self makeTextField:nil
                            placeholder:NSLocalizedString(@"Required", nil)
                            indexPath:indexPath secureTextEntry:YES
                        ];
                        self.password1TextField.delegate = self;
                        [cell.contentView addSubview:self.password1TextField];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self
                            selector:@selector(textFieldTextDidChangeNotification:)
                            name:UITextFieldTextDidChangeNotification 
                            object:self.password1TextField
                        ];
                    }
                    
                    self.password1TextField.frame = CGRectMake(
                        122.0f, 13.0f,
                        cell.contentView.frame.size.width - 132.0f, 22.0f
                    );
                }
                break;
                case 2:
                {
                    cell.textLabel.text = NSLocalizedString(@"Verify", nil);
                    
                    if (!self.password2TextField)
                    {
                        self.password2TextField = [self makeTextField:nil
                            placeholder:NSLocalizedString(@"Retype password", nil)
                            indexPath:indexPath secureTextEntry:YES
                        ];
                        self.password2TextField.delegate = self;
                        self.password2TextField.autoresizingMask =
                            UIViewAutoresizingFlexibleWidth 
                        ;
                        [cell.contentView addSubview:self.password2TextField];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self
                            selector:@selector(textFieldTextDidChangeNotification:)
                            name:UITextFieldTextDidChangeNotification 
                            object:self.password2TextField
                        ];
                    }
                    
                    self.password2TextField.frame = CGRectMake(
                        122.0f, 13.0f,
                        cell.contentView.frame.size.width - 132.0f, 22.0f
                    );
                }
                break;
                default:
                break;
            }
        }
        break;
        case 1:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = NSLocalizedString(@"Secret", nil);
                    
                    if (!self.secretTextField)
                    {
                        self.secretTextField = [self makeTextField:nil
                            placeholder:NSLocalizedString(@"Optional", nil)
                            indexPath:indexPath secureTextEntry:NO
                        ];
                        self.secretTextField.delegate = self;
                        self.secretTextField.autoresizingMask =
                            UIViewAutoresizingFlexibleWidth 
                        ;
                        [cell.contentView addSubview:self.secretTextField];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self
                            selector:@selector(textFieldTextDidChangeNotification:)
                            name:UITextFieldTextDidChangeNotification 
                            object:self.secretTextField
                        ];
                    }
                    
                    self.secretTextField.frame = CGRectMake(
                        122.0f, 13.0f,
                        cell.contentView.frame.size.width - 132.0f, 22.0f
                    );
                }
                break;
                default:
                break;
            }
        }
        break;
        case 2:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    cell.textLabel.text = NSLocalizedString(@"Sign Up", nil);
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    cell.textLabel.textColor = self.signUpEnabled ?
                        [UIColor blackColor] : [UIColor grayColor]
                    ;
                }
                break;
                default:
                break;
            }
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
    if (indexPath.section == 2 && indexPath.row == 0)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [self signUp];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
            return NO;
        case 1:
            return NO;
        case 2:
            return self.signUpEnabled;
        default:
            break;
    }
    
    return YES;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    self.signUpEnabled =
        self.usernameTextField.text.length >= 5 &&
        self.password1TextField.text.length >= 8 &&
        self.password2TextField.text.length >= 8 &&
        [self.password1TextField.text isEqualToString:
        self.password2TextField.text]
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
        [self.password1TextField becomeFirstResponder];
    }
    else if (textField == self.password1TextField)
    {
        [self.password2TextField becomeFirstResponder];
    }
    else if (textField == self.password2TextField)
    {
        [self.secretTextField becomeFirstResponder];
    }
    else if (textField == self.secretTextField)
    {
        [self.usernameTextField becomeFirstResponder];
    }
    
    return NO;
}

#pragma mark -

- (void)textFieldTextDidChangeNotification:(NSNotification *)aNotification
{
    self.signUpEnabled =
        self.usernameTextField.text.length >= 5 &&
        self.password1TextField.text.length >= 8 &&
        self.password2TextField.text.length >= 8 &&
        [self.password1TextField.text isEqualToString:
        self.password2TextField.text]
    ;
    
    [self.tableView reloadRowsAtIndexPaths:
        [NSArray arrayWithObjects:
        [NSIndexPath indexPathForRow:0 inSection:2],
        nil] withRowAnimation:UITableViewRowAnimationNone
    ];
}

#pragma mark -

- (void)signUp
{
    NSLog(@"signUp");
    
    [self.usernameTextField resignFirstResponder];
    [self.password1TextField resignFirstResponder];
    [self.password2TextField resignFirstResponder];
    [self.secretTextField resignFirstResponder];

	self.progressHUD = [[MBProgressHUD alloc] initWithView:
        self.navigationController.view
    ];
    [self.view.window addSubview:self.progressHUD];
    [self.progressHUD setMode:MBProgressHUDModeIndeterminate];
	[self.progressHUD show:YES];
    
    self.responseData = [NSMutableData data];

    NSURL * url = [NSURL URLWithString:
        [NSString stringWithFormat:@"https://grapevine.am/register?u=%@&p=%@&ss=%@",
        self.usernameTextField.text, self.password1TextField.text,
        self.secretTextField.text]
    ];

    NSLog(@"Signing up, url = %@", url);

    self.urlConnection = [NSURLConnection connectionWithRequest:
        [NSURLRequest requestWithURL:url] delegate:self
    ];

    [self.urlConnection start];
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

- (void)connection:(NSURLConnection *)connection
    didFailWithError:(NSError *)error
{
    NSLog(@"error = %@", error);
    
    self.responseData = 0;
}

- (void)connection:(NSURLConnection *)connection
    didReceiveResponse:(NSURLResponse *)response
{
    self.responseData.length = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary * json = [NSJSONSerialization
        JSONObjectWithData:self.responseData options:0 error:nil
    ];
    
    NSString * message = [json objectForKey:@"message"];
    NSString * status = [json objectForKey:@"status"];
    
    if (status && status.intValue == 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:
            self.usernameTextField.text forKey:@"username"
        ];
        
        NSMutableDictionary * preferences = [[[NSUserDefaults
            standardUserDefaults] objectForKey:self.usernameTextField.text]
            mutableCopy
        ];
        
        if (!preferences)
        {
            [[NSUserDefaults standardUserDefaults] setObject:
                [NSMutableDictionary new] forKey:self.usernameTextField.text
            ];
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[GVStack sharedInstance] signIn:
            self.usernameTextField.text password:self.password1TextField.text
        ];
        
        [self.progressHUD hide:YES];
        [self.progressHUD removeFromSuperview];
        self.progressHUD = nil;
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        NSLog(
            NSLocalizedString(
            @"Registration failed (%@), please try again.", nil), message
        );
        
        [self.progressHUD setMode:MBProgressHUDModeText];
        
        [self.progressHUD setLabelText:
            [NSString stringWithFormat:NSLocalizedString(
            @"Error (%@)", nil), message]
        ];
        
        [self.progressHUD performSelector:@selector(removeFromSuperview)
            withObject:nil afterDelay:3.0f
        ];
    }
    
    self.responseData = 0;
}

- (BOOL)connection:(NSURLConnection *)connection
    canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod
        isEqualToString:NSURLAuthenticationMethodServerTrust
    ];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (
        [challenge.protectionSpace.authenticationMethod
            isEqualToString:NSURLAuthenticationMethodServerTrust]
        )
    {
        if (
            [challenge.protectionSpace.host
            rangeOfString:@"grapevine.am"].location != NSNotFound
            )
        {
            [challenge.sender useCredential:
                [NSURLCredential credentialForTrust:
                challenge.protectionSpace.serverTrust]
                forAuthenticationChallenge:challenge
            ];
        }
    }

    [challenge.sender
        continueWithoutCredentialForAuthenticationChallenge:challenge
    ];
}

@end
