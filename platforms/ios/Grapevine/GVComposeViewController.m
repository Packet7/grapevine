//
//  GVComposeViewController.m
//  Grapevine
//
//  Created by Packet7, LLC. on 8/19/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "MBProgressHUD.h"

#import "UIImage+Resize.h"

#import "GVAlert.h"
#import "GVAppDelegate.h"
#import "GVComposeViewController.h"
#import "GVTimelineTableViewController.h"

/**
 * http://stackoverflow.com/questions/3372333/ipad-keyboard-will-not-dismiss-if-modal-view-controller-presentation-style-is-ui
 */
@implementation UINavigationController(KeyboardDismiss)
- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}
@end

@interface GVComposeViewController ()
@property (assign) IBOutlet UITextView * textView;
@property (assign) IBOutlet UIImageView * imageView;
@property (assign) IBOutlet UILabel * charactersLabel;
@property (assign) IBOutlet UIToolbar * toolbar;
@property (assign) IBOutlet UIBarButtonItem * cameraBarButtonItem;
@property (strong) NSMutableArray * files;
@property (strong) UIPopoverController * imagePickerPopoverController;
@property (assign) CGRect oldToolbarRect;
@property (assign) CGRect oldContentViewRect;

- (IBAction)pickPhoto:(id)sender;

@end

@implementation GVComposeViewController

- (id)init
{
    self = [super initWithNibName:@"ComposeViewController" bundle:[NSBundle mainBundle]];
    
    if (self) {
        self.files = [NSMutableArray new];

        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(keyboardWillHide:) 
            name:UIKeyboardWillHideNotification object:nil
        ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(keyboardWillShow:) 
            name:UIKeyboardWillShowNotification object:nil
        ];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Compose", nil);
    
    self.navigationItem.prompt = [NSString
        stringWithFormat:@"%@%d",
        self.textView.text.length < 141 ? @"" :
        @"-", self.textView.text.length
    ];
    
    UIBarButtonItem * cancelBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:NSLocalizedString(@"Cancel", nil)
        style:UIBarButtonItemStyleBordered target:self
        action:@selector(cancel:)
    ];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    
    UIBarButtonItem * publishBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:NSLocalizedString(@"Publish", nil)
        style:UIBarButtonItemStyleBordered target:self
        action:@selector(publish:)
    ];
    self.navigationItem.rightBarButtonItem = publishBarButtonItem;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.imageView.layer.cornerRadius = 3.0f;
    self.imageView.layer.masksToBounds = YES;
    self.imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer * tapGestureRecognizer = [[UITapGestureRecognizer
        alloc] initWithTarget:self action:@selector(pickPhoto:)
    ];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.imageView addGestureRecognizer:tapGestureRecognizer];
    
    self.textView.font = [UIFont fontWithName:@"Droid Sans" size:14.0f];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.textView performSelector:@selector(becomeFirstResponder)
        withObject:nil afterDelay:0.01f
    ];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)publish:(id)sender
{
    [self.textView resignFirstResponder];
    
    NSString * message = self.textView.text;
#define FILTER_PORN 1
#if (defined FILTER_PORN && FILTER_PORN)
    /**
     * Check for sexual, etc content.
     */
    if (
        [message rangeOfString:@"#porn" options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [message rangeOfString:@"#pr0n" options:NSCaseInsensitiveSearch].location != NSNotFound
        )
    {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:
            NSLocalizedString(@"Naughty!", nil) message:
            NSLocalizedString(@"This is not a porn service, please clean up your post and try again.", nil)
            delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil)
            otherButtonTitles:nil, nil
        ];
        
        [alertView show];
        
        return;
    }
#endif // FILTER_PORN

    [sender setEnabled:NO];
    
    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:
        self.view.window animated:YES
    ];
    
    hud.labelText = NSLocalizedString(@"Publishing", nil);
    
    if (self.files.count > 0)
    {
        [self performSelectorInBackground:@selector(postBackground:)
            withObject:message
        ];
    }
    else
    {
        [[GVStack sharedInstance] post:message];
        
        [self.files removeAllObjects];
        
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
        
        [MBProgressHUD hideHUDForView:self.view.window
            animated:YES
        ];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)postBackground:(NSString *)message
{
    NSString * url = [self uploadImage];
    
    if (url)
    {
        message = [message stringByAppendingFormat:@" %@", url];
        
        dispatch_async(dispatch_get_main_queue(),^
        {
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
            
            [MBProgressHUD hideHUDForView:self.view.window
                animated:YES
            ];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(),^
        {
            [[GVAlert sharedInstance] showWithFileSizeTooLarge];
            
            
        });
    }
}

- (IBAction)pickPhoto:(id)sender
{
    [self.textView resignFirstResponder];
    
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil
        delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
		destructiveButtonTitle:nil
        otherButtonTitles:NSLocalizedString(@"Take Photo", nil), 
		NSLocalizedString(@"Choose Photo", nil), nil
    ];
    
    sheet.tag = 1;
	
    [sheet showFromBarButtonItem:sender animated:YES];
}

#pragma mark UIActionSheetDelegate Methods -

- (void)actionSheet:(UIActionSheet *)actionSheet 
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"buttonIndex = %d", buttonIndex);
    
    if (actionSheet.tag == 0)
    {
        switch (buttonIndex)
        {		
            case 0:
            {
                // ...
            }
            break;
            default:
            break;
        }
    }
    else
    {
        switch (buttonIndex)
        {		
            case 0:
            {
                if (
                    [UIImagePickerController isCameraDeviceAvailable:
                    UIImagePickerControllerCameraDeviceFront]
                    )
                {
                    [self showImagePicker:
                        UIImagePickerControllerSourceTypeCamera
                    ];
                }
            }
            break;
            case 1:
            {
                [self showImagePicker:
                    UIImagePickerControllerSourceTypePhotoLibrary
                ];
            }
            break;
            default:
            break;
        }
    }
}

- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType
{
    if (
        [UIImagePickerController
        isSourceTypeAvailable:sourceType]
        )
    {
        UIImagePickerController * imagePickerController;
        
        imagePickerController = [[UIImagePickerController alloc] init];
        
        imagePickerController.sourceType = sourceType;
        
        if (sourceType == UIImagePickerControllerSourceTypeCamera)
        {
            imagePickerController.allowsEditing = true;
        }
        
        imagePickerController.delegate = (id <UIImagePickerControllerDelegate>)self;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            [self
                presentViewController:imagePickerController animated:YES
                completion:nil
            ];
        }
        else
        {
            self.imagePickerPopoverController = [[UIPopoverController alloc]
                initWithContentViewController:imagePickerController
            ];
            
            self.imagePickerPopoverController.delegate = self;
#if 0
            CGRect rect = self.imageView.frame;

            [self.imagePickerPopoverController presentPopoverFromRect:rect
                inView:self.view permittedArrowDirections:
                UIPopoverArrowDirectionAny animated:YES
            ];
#else
            [self.imagePickerPopoverController 
                presentPopoverFromBarButtonItem:self.cameraBarButtonItem
                permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES
            ];
#endif
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingImage:(UIImage *)img editingInfo:(NSDictionary *)editInfo
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
    }
    
    UIImage * image = [img
        resizedImageToFitInSize:CGSizeMake(1280.0f, 720.0f) scaleIfSmaller:NO
    ];
    
    [self.files addObject:image];

    self.imageView.image = image;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
    }
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(
    UIPopoverController *)popoverController
{ 
    return YES;
}
 
- (void)popoverControllerDidDismissPopover:(
    UIPopoverController *)popoverController
{
    // ...
}

#pragma mark -
#pragma mark UIKeyboard

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    UIViewAnimationCurve animationCurve = (UIViewAnimationCurve)[[[
        aNotification userInfo] 
        objectForKey:UIKeyboardAnimationDurationUserInfoKey] 
        unsignedIntValue
    ];
    
    double animationDuration = [[[aNotification userInfo] 
        objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue
    ];

    [UIView beginAnimations:nil context:UIGraphicsGetCurrentContext()];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        self.toolbar.frame = self.oldToolbarRect;
    }
    else
    {
        // ...
    }
    
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    UIViewAnimationCurve animationCurve = (UIViewAnimationCurve)[[[
		aNotification userInfo] 
		objectForKey:UIKeyboardAnimationDurationUserInfoKey] unsignedIntValue
	];
    
	double animationDuration = [[[aNotification userInfo] 
		objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue
	];
    
    CGRect keyboardBounds;

    CGRect keyboardEndFrame;

    [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] 
		getValue:&keyboardEndFrame
	];

    keyboardBounds = [self.view convertRect:keyboardEndFrame toView:nil];

    [UIView beginAnimations:nil context:UIGraphicsGetCurrentContext()];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
        
    CGRect toolbarFrame = self.toolbar.frame;
    
    self.oldToolbarRect = self.toolbar.frame;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        toolbarFrame.origin.y -= keyboardBounds.size.height;
	}
    else
    {
        // ...
    }
    
    self.toolbar.frame = toolbarFrame;
    
    [UIView commitAnimations];
}

#pragma mark -

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == self.textView)
    {
        NSString * message = self.textView.text;
        
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
    
    self.charactersLabel.text = [NSString
        stringWithFormat:@"%@%d",
        self.textView.text.length < 141 ? @"" :
        @"-", self.textView.text.length
    ];
    
    self.navigationItem.rightBarButtonItem.enabled = 
        self.textView.text.length > 0 &&
        self.textView.text.length < 141
    ;
    
    self.navigationItem.prompt = [NSString
        stringWithFormat:@"%@%d",
        self.textView.text.length < 141 ? @"" :
        @"-", self.textView.text.length
    ];
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
    
    NSString * message = self.textView.text;

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

                    self.textView.text = finalMessage;

                    self.charactersLabel.text = [NSString
                        stringWithFormat:@"%@%d",
                        self.textView.text.length < 141 ? @"" :
                        @"-", self.textView.text.length
                    ];
                    
                    self.navigationItem.rightBarButtonItem.enabled =
                        self.textView.text.length > 0 &&
                        self.textView.text.length < 141
                    ;
                }
            }
        }];
    }
}

#pragma mark -

- (NSString *)uploadImage
{
    NSData * data = UIImageJPEGRepresentation(self.files.lastObject, 0.5f);

	NSString * urlString = @"http://grp.yt/p/upload.php";	
	
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:urlString]];
	[request setHTTPMethod:@"POST"];
	
	NSString * boundary = @"0xKhTmLbOuNdArY";  
	NSString * contentType = [NSString stringWithFormat:
        @"multipart/form-data; boundary=%@", boundary, nil
    ];
	[request addValue:contentType forHTTPHeaderField:@"Content-Type"];
	
	NSMutableData * body = [NSMutableData data];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"foo.%@\"\r\n", @"jpg"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:data];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:body];
	
	NSData * returnData = [NSURLConnection sendSynchronousRequest:request
        returningResponse:nil error:nil
    ];
	
    NSDictionary * json = [NSJSONSerialization
        JSONObjectWithData:returnData options:0 error:nil
    ];

	NSLog(@"json = %@", json);
 
    return [json objectForKey:@"url"];
}

@end
