/**
 * Copyright (C) 2013 Packet7, LLC.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "FNAppDelegate.h"
#import "FNAvatarCache.h"
#import "FNEditProfileWindowController.h"
#import "GVStack.h"

@interface FNEditProfileWindowController ()
@property (assign) IBOutlet NSImageView * photoImageView;
@property (assign) IBOutlet NSTextField * fullnameTextField;
@property (assign) IBOutlet NSTextField * locationTextField;
@property (assign) IBOutlet NSTextField * photoTextField;
@property (assign) IBOutlet NSTextField * webTextField;
@property (assign) IBOutlet NSTextField * descriptionTextField;
@property (assign) IBOutlet NSButton * publishButton;

- (void)updateProfile:(NSDictionary *)aProfile;

@end

@implementation FNEditProfileWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"EditProfileWindow" owner:self];
    
    if (self)
    {
        [[self window] setLevel:NSStatusWindowLevel];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(didDownloadMyPhotoNotification:)
            name:kGVDidDownloadMyPhotoNotification object:nil
        ];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString * username = [userDefaults objectForKey:@"username"];
    
    NSDictionary * preferences = [userDefaults objectForKey:username];
    
    NSDictionary * profile = [preferences objectForKey:@"profile"];

    if ([profile objectForKey:@"f"])
    {
        self.fullnameTextField.stringValue = [profile objectForKey:@"f"];
    }
    
    if ([profile objectForKey:@"l"])
    {
        self.locationTextField.stringValue = [profile objectForKey:@"l"];
    }
    
    if ([profile objectForKey:@"p"])
    {
        self.photoTextField.stringValue = [profile objectForKey:@"p"];
    }
    
    if ([profile objectForKey:@"w"])
    {
        self.webTextField.stringValue = [profile objectForKey:@"w"];
    }
    
    if ([profile objectForKey:@"b"])
    {
        self.descriptionTextField.stringValue = [profile objectForKey:@"b"];
    }
    
    NSImage * image = [[FNAvatarCache sharedInstance]
        objectForKey:[profile objectForKey:@"p"]
    ];
    
    if (image)
    {
        self.photoImageView.image = image;
    }
    else
    {
        self.photoImageView.image = [[FNAvatarCache sharedInstance]
            objectForKey:@"default"
        ];
    }
}

- (IBAction)update:(id)sender
{
    [sender setEnabled:NO];
    
    NSString * f = self.fullnameTextField.stringValue;
    
    NSString * l = self.locationTextField.stringValue;
    
    NSString * p = self.photoTextField.stringValue;

    NSString * w = self.webTextField.stringValue;
    
    NSString * b = self.descriptionTextField.stringValue;
    
    NSMutableDictionary * profile = [NSMutableDictionary dictionary];
    
    [profile setObject:f forKey:@"f"];
    [profile setObject:l forKey:@"l"];
    [profile setObject:p forKey:@"p"];
    [profile setObject:w forKey:@"w"];
    [profile setObject:b forKey:@"b"];
    
    [self performSelectorInBackground:@selector(updateProfile:)
        withObject:profile
    ];
}

- (IBAction)cancel:(id)sender
{
    [self.popover performClose:nil];
}

- (void)updateProfile:(NSDictionary *)aProfile
{
    NSString * f = [aProfile objectForKey:@"f"];
    
    NSString * l = [aProfile objectForKey:@"l"];
    
    NSString * p = [aProfile objectForKey:@"p"];
    
    if (p.length > 0)
    {
        NSString * p2 = [self synchronousShorten:p];
        
        if (p2 && p2.length)
        {
            p = [self synchronousShorten:p];
        }
    }
    
    NSString * w = [aProfile objectForKey:@"w"];
    
    if (w.length > 0)
    {
        NSString * w2 = [self synchronousShorten:w];
        
        if (w2 && w2.length)
        {
            w = w2;
        }
    }
    
    NSString * b = [aProfile objectForKey:@"b"];
    
    NSMutableDictionary * profile = [NSMutableDictionary dictionary];
    
    if (f && f.length)
    {
        [profile setObject:f forKey:@"f"];
    }
    
    if (l && l.length)
    {
        [profile setObject:l forKey:@"l"];
    }
    
    if (p && p.length)
    {
        [profile setObject:p forKey:@"p"];
    }
    
    if (w && w.length)
    {
        [profile setObject:w forKey:@"w"];
    }
    
    if (b && b.length)
    {
        [profile setObject:b forKey:@"b"];
    }
    
    // :TODO: [profile setObject:nil forKey:@"a"];
    // :TODO: [profile setObject:nil forKey:@"g"]
    
    dispatch_async(dispatch_get_main_queue(),^
    {
        if (p)
        {
            self.photoTextField.stringValue = p;
        }
        
        if (w)
        {
            self.webTextField.stringValue = w;
        }
        
        NSString * username = [[NSUserDefaults standardUserDefaults]
            objectForKey:@"username"
        ];
        
        NSMutableDictionary * preferences = [[[NSUserDefaults
            standardUserDefaults] objectForKey:username] mutableCopy
        ];
        
        [preferences setObject:profile forKey:@"profile"];
        
        [[NSUserDefaults standardUserDefaults] setObject:preferences
            forKey:username
        ];
        
        [[NSUserDefaults standardUserDefaults] synchronize];

        [[NSApp delegate] updateProfile:nil];
        
        [self performSelector:@selector(close)
            withObject:nil afterDelay:1.0f
        ];
    });
}

- (void)close
{
    [self.popover performClose:nil];
    
    [self.publishButton setEnabled:YES];
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

#pragma mark -

- (void)didDownloadMyPhotoNotification:(NSNotification *)aNotification
{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString * username = [userDefaults objectForKey:@"username"];
    
    NSDictionary * preferences = [userDefaults objectForKey:username];
    
    NSDictionary * profile = [preferences objectForKey:@"profile"];
    
    NSImage * image = [[FNAvatarCache sharedInstance]
        objectForKey:[profile objectForKey:@"p"]
    ];
    
    if (image)
    {
        self.photoImageView.image = image;
    }
    else
    {
        self.photoImageView.image = [[FNAvatarCache sharedInstance]
            objectForKey:@"default"
        ];
    }
}

#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
