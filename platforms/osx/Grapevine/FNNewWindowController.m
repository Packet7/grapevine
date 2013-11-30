//
//  FNNewWindowController.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/14/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "NSImage+RoundCorner.h"

#import "FNNewWindowController.h"
#import "GVStack.h"

@interface FNNewWindowController ()
@property (assign) IBOutlet NSTextField * charCountTextField;
@property (assign) IBOutlet NSButton * sendButton;
@property (assign) IBOutlet NSImageView * imageView;
@property (strong) NSMutableArray * files;
@end

@implementation FNNewWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"NewMessage" owner:self];
    
    if (self)
    {
        [self window];
        self.files = [NSMutableArray new];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self.charCountTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - NSTextFieldDelegate

- (void)validate:(NSTextField *)aTextfield
{
    NSTextField * textField = aTextfield;
    
    NSString * message = textField.stringValue;
    
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
            
            [self shorten:nil];
        }
    }
    
    self.charCountTextField.stringValue = [NSString
        stringWithFormat:@"%@%zu",
        textField.stringValue.length < 141 ? @"" :
        @"-", textField.stringValue.length
    ];
    
    [self.sendButton setEnabled:
        textField.stringValue.length > 0 &&
        textField.stringValue.length < 141
    ];
}

- (void)controlTextDidChange:(NSNotification *)notification
{
    [self validate:notification.object];
}

#pragma mark - 

- (IBAction)post:(id)sender
{
    [self.sendButton setEnabled:NO];
    
    NSString * message = self.messageTextField.stringValue;

    if (self.files.count > 0)
    {
        [self performSelectorInBackground:@selector(postBackground:)
            withObject:message
        ];
    }
    else
    {
        [[GVStack sharedInstance] post:message];
        
        [self.popover close];
        
        self.messageTextField.stringValue = @"";
        self.charCountTextField.stringValue = @"0";
        
        self.imageView.image = [NSImage new];
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
            
            [self.popover close];
            
            self.messageTextField.stringValue = @"";
            self.charCountTextField.stringValue = @"0";
            
            self.imageView.image = [NSImage new];
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
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(),^
        {
            NSAlert * alert = [[NSAlert alloc] init];

            alert.informativeText = NSLocalizedString(
                @"The file is too big.", nil
            );
            alert.messageText = NSLocalizedString(@"Opps!", nil);
            
            [alert runModal];
            
            self.imageView.image = [NSImage new];
            [self.files removeAllObjects];
            
            [self.sendButton setEnabled:YES];
        });
    }
}

- (IBAction)shorten:(id)sender
{
    /**
     * Test: I want this #watch from @omega http://goo.gl/9EAy5 http://195.154.205.140/mesIMG/imgStd/21509.jpg http://4.bp.blogspot.com/-DIszQN87fJ4/Ti1nzFf8eqI/AAAAAAAAQrs/XD5Jf_a18BI/s400/OMEGA%2BSeamaster%2BPlanet%2BOcean%2BLiquidmetal%2BTitanium%2BChrono%2B9300%2B15.JPG
     */
    NSMutableString * finalMessage = [NSMutableString string];
    
    NSMutableArray * unprocessedUrls = [NSMutableArray array];
    NSMutableDictionary * processedUrls = [NSMutableDictionary dictionary];
    
    NSString * message = self.messageTextField.stringValue;

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

                    self.messageTextField.stringValue = finalMessage;
                    
                    self.charCountTextField.stringValue = [NSString
                        stringWithFormat:@"%@%zu",
                        self.messageTextField.stringValue.length < 141 ? @"" :
                        @"-", self.messageTextField.stringValue.length
                    ];
                    
                    [self.sendButton setEnabled:
                        self.messageTextField.stringValue.length > 0 &&
                        self.messageTextField.stringValue.length < 141
                    ];
                }
            }
        }];
    }
}

- (IBAction)cancel:(id)sender
{
    [self.popover close];
    
    self.messageTextField.stringValue = @"";
    self.charCountTextField.stringValue = @"0";
    
    self.imageView.image = [NSImage new];
    [self.files removeAllObjects];
}

- (IBAction)pickFile:(id)sender
{
    NSOpenPanel * openDlg = [NSOpenPanel openPanel];

    openDlg.canCreateDirectories = NO;
    openDlg.canSelectHiddenExtension = NO;
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];

    openDlg.prompt = NSLocalizedString(@"Choose", nil);

    if ([openDlg runModal] == NSOKButton)
    {
        NSURL * url = openDlg.URLs.lastObject;

        [self.files removeAllObjects];
        [self.files addObject:url];
        
        NSImage * image = [[NSImage alloc] initWithContentsOfURL:url];
        
        image = [image resize:NSMakeSize(84, 84)];
        
        image = [image roundCornersImageCornerRadius:4.0f];
        
        self.imageView.image = image;
    }
}

#pragma mark -

- (NSString *)uploadImage
{
    NSURL * url = self.files.lastObject;

    NSData * data = [[NSData alloc] initWithContentsOfURL:self.files.lastObject];

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
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"foo.%@\"\r\n", url.pathExtension] dataUsingEncoding:NSUTF8StringEncoding]];
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
