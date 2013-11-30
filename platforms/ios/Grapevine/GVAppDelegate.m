//
//  GVAppDelegate.m
//  Grapevine
//
//  Created by Packet7, LLC. on 7/26/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "MBProgressHUD.h"

#import "GVAlert.h"
#import "GVAppDelegate.h"
#import "GVEditProfileViewController.h"
#import "GVNavigationBar.h"
#import "GVSignInViewController.h"
#import "GVStack.h"
#import "GVTimelineTableViewController.h"

@interface GVAppDelegate ()
@property (assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@end

@implementation GVAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.timelineTableViewController = [[GVTimelineTableViewController
        alloc] initWithStyle:UITableViewStylePlain
        viewControllerType:GVViewControllerTypeFeed
    ];

    /**
     * Add the default avatar to the avatar cache.
     */
    [[GVAvatarCache sharedInstance] setObject:[UIImage imageNamed:@"Avatar"]
        forKey:@"default"
    ];
    
    /** */
    
    UINavigationController * navigationController = [[UINavigationController
        alloc] initWithRootViewController:self.timelineTableViewController
    ];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        navigationController.navigationBar.tintColor = [UIColor purpleColor];
    }
    
//    //if ([[UINavigationBar appearance] respondsToSelector:@selector(setBarTintColor:)])
//    {
//        [[UINavigationBar appearance] setBarTintColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5f]];
//    }
    if ([self.window respondsToSelector:@selector(setTintColor:)])
    {
        self.window.tintColor = [UIColor purpleColor];
    }
    
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    GVSignInViewController * signInViewController = [[GVSignInViewController
        alloc] initWithStyle:UITableViewStyleGrouped
    ];
    
    navigationController = [[UINavigationController
        alloc] initWithRootViewController:signInViewController
    ];

    [self.timelineTableViewController.navigationController
        presentViewController:navigationController animated:NO completion:nil
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(didConnectNotification:)
        name:kGVDidConnectNotification object:nil
    ];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(didDisconnectNotification:)
        name:kGVDidDisconnectNotification object:nil
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(didSignInNotification:)
        name:kGVDidSignInNotification object:nil
    ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(didFindProfileNotification:)
        name:kGVDidFindProfileNotification object:nil
    ];
    
    [[GVStack sharedInstance] start];
#if 0 // for testing
    [[NSUserDefaults standardUserDefaults] setObject:
        [NSNumber numberWithBool:NO] forKey:kGVDidReviewTOS02
    ];
#endif
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kGVDidReviewTOS02])
    {
        [[GVAlert sharedInstance] showWithTOS];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /**
     * Set the keep-alive handler.
     */
    [[UIApplication sharedApplication] setKeepAliveTimeout:600
        handler:^
    {
        NSLog(@"keepAlive");
        
        if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid)
        {
            self.backgroundTaskIdentifier = [
                [UIApplication sharedApplication]
                beginBackgroundTaskWithExpirationHandler:^
            {
                [[UIApplication sharedApplication] endBackgroundTask:
                    self.backgroundTaskIdentifier
                ];
                
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }];

            NSLog(
                @"backgroundTaskIdentifier = %d, backgroundTimeRemaining = %.2f",
                self.backgroundTaskIdentifier,
                [UIApplication sharedApplication].backgroundTimeRemaining
            );
            
            [self performSelector:@selector(endBackgroundTask)
                withObject:nil afterDelay:60.0f
            ];
        }
    }];
    
    if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid)
    {
        self.backgroundTaskIdentifier = [
            [UIApplication sharedApplication]
            beginBackgroundTaskWithExpirationHandler:^
        {
            [[UIApplication sharedApplication] endBackgroundTask:
                self.backgroundTaskIdentifier
            ];
            
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];

        NSLog(
            @"backgroundTaskIdentifier = %d, backgroundTimeRemaining = %.2f",
            self.backgroundTaskIdentifier,
            [UIApplication sharedApplication].backgroundTimeRemaining
        );
        
        [self performSelector:@selector(endBackgroundTask)
            withObject:nil afterDelay:90.0f
        ];
    }
}

- (void)endBackgroundTask
{
    NSLog(@"Ending background task %d.", self.backgroundTaskIdentifier);
    
    [[UIApplication sharedApplication] endBackgroundTask:
        self.backgroundTaskIdentifier
    ];
    
    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /**
     * Clear the keep-alive.
     */
    [application clearKeepAliveTimeout];
    
    /**
     * Cancel all local notifications.
     */
    [application cancelAllLocalNotifications];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -

- (void)didConnectNotification:(NSNotification *)aNotification
{
    [MBProgressHUD hideHUDForView:self.timelineTableViewController.view.window
        animated:YES
    ];
}

- (void)didDisconnectNotification:(NSNotification *)aNotification
{
    if (self.timelineTableViewController.view.window)
    {
        MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:
            self.timelineTableViewController.view.window animated:YES
        ];
        
        hud.labelText = NSLocalizedString(@"Connecting", nil);
    }
}

- (void)didSignInNotification:(NSNotification *)aNotification
{
    NSDictionary * dict  = aNotification.object;
    
    if ([[dict objectForKey:@"status"] intValue] == 0)
    {
        [self performSelector:@selector(setupSubscriptions) withObject:nil afterDelay:0.25f];
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
    
    if (u && [u isEqualToString:username])
    {
        NSMutableDictionary * preferences = [[[NSUserDefaults
            standardUserDefaults] objectForKey:username] mutableCopy
        ];
        
        NSMutableDictionary * profile = [[preferences
            objectForKey:@"profile"] mutableCopy
        ];
        
        NSDate * expires1 = [dict objectForKey:@"__t"];
        NSDate * expires2 = [profile objectForKey:@"__t"];

        NSTimeInterval lifetime1 = [[NSDate date]
            timeIntervalSinceDate:expires1
        ];
        
        NSTimeInterval lifetime2 = [[NSDate date]
            timeIntervalSinceDate:expires2
        ];
 
        //NSLog(@"%@: t1 = %.2f, t2 = %.2f", u, lifetime1, lifetime2);
        
        if (!expires2 || lifetime1 < lifetime2)
        {
            profile = [NSMutableDictionary new];

            [profile addEntriesFromDictionary:dict];
            
            [preferences setObject:profile forKey:@"profile"];
            
            [[NSUserDefaults standardUserDefaults] setObject:preferences
                forKey:username
            ];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[GVProfileCache sharedInstance] setProfile:profile
                username:username
            ];
        }
    }
}

#pragma mark -

- (void)goEditProfile:(id)sender
{
    GVEditProfileViewController * editProfileViewController =
        [[GVEditProfileViewController alloc] initWithStyle:
        UITableViewStylePlain
    ];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self.timelineTableViewController.navigationController
            pushViewController:editProfileViewController animated:YES
        ];
    }
    else
    {
        if (
            self.editProfilePopoverController &&
            [self.editProfilePopoverController isPopoverVisible]
            )
        {
            [self.editProfilePopoverController dismissPopoverAnimated:YES];
        }
        else
        {
            UINavigationController * navigationController = [[UINavigationController
                alloc] initWithRootViewController:editProfileViewController
            ];
    
            self.editProfilePopoverController = [[UIPopoverController alloc]
                initWithContentViewController:navigationController
            ];
            
			self.editProfilePopoverController.popoverContentSize =
				CGSizeMake(320.0, 420.0)
			;
            
            [self.editProfilePopoverController
                presentPopoverFromBarButtonItem:sender
                permittedArrowDirections:UIPopoverArrowDirectionAny
                animated:YES
            ];
        }
    }
}

- (IBAction)goSearch:(id)sender
{
    GVTimelineTableViewController * timelineTableViewController2 = [[
        GVTimelineTableViewController alloc] initWithStyle:UITableViewStylePlain
        viewControllerType:GVViewControllerTypeSearch
    ];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self.timelineTableViewController.navigationController
            pushViewController:timelineTableViewController2 animated:YES
        ];
    }
    else
    {
        UINavigationController * navigationController = [[UINavigationController
            alloc] initWithRootViewController:timelineTableViewController2
        ];
        
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self.timelineTableViewController presentViewController:
            navigationController animated:YES completion:nil
        ];
    }
}

- (IBAction)signOut:(id)sender
{    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[GVStack sharedInstance] signOut];

    [self.timelineTableViewController reset];
    
    GVSignInViewController * signInViewController = [[GVSignInViewController
        alloc] initWithStyle:UITableViewStyleGrouped
    ];
    
    UINavigationController * navigationController = [[UINavigationController
        alloc] initWithRootViewController:signInViewController
    ];

    [self.timelineTableViewController.navigationController
        presentViewController:navigationController animated:NO completion:nil
    ];
}

#pragma mark -

- (void)setupSubscriptions
{
    NSString * username = [[NSUserDefaults
        standardUserDefaults] objectForKey:@"username"]
    ;
    
    NSMutableDictionary * preferences = [[[NSUserDefaults
        standardUserDefaults] objectForKey:username] mutableCopy
    ];
    
    NSDictionary * profile = [preferences objectForKey:@"profile"];
    
    if (profile)
    {
        [[GVProfileCache sharedInstance] setProfile:profile username:username];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[GVStack sharedInstance] subscribe:username];
    [[GVStack sharedInstance] subscribe:@"grapevine"];
}

@end
