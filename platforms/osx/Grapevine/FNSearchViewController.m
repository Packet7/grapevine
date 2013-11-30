//
//  FNSearchViewController.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/15/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "FNAppDelegate.h"
#import "FNMessageController.h"
#import "FNSearchViewController.h"

@interface FNSearchViewController ()
@property (assign) NSInteger transactionId;
@property (assign) IBOutlet NSProgressIndicator * progressIndicatorOne;
@property (assign) IBOutlet NSProgressIndicator * progressIndicatorTwo;
@property (assign) IBOutlet FNMessageController * messageViewController;
@end

@implementation FNSearchViewController

- (id)init
{
    self = [super initWithNibName:@"SearchView" bundle:[NSBundle mainBundle]];
    
    if (self)
    {
        self.transactionId = 0;
        self.searchType = 1;
    }
    
    return self;
}

- (void)awakeFromNib
{
    [[[self.searchField cell] cancelButtonCell] setAction:@selector(clear:)];
    [[[self.searchField cell] cancelButtonCell] setTarget:self];
    
    self.messageViewController.messageControllerType =
        FNMessageControllerTypeSearch
    ;
}

- (IBAction)selectSearchType:(id)sender
{
    self.searchType = [sender tag];
}

- (IBAction)search:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:
        self.progressIndicatorOne
        selector:@selector(stopAnimation:) object:nil
    ];
    [NSObject cancelPreviousPerformRequestsWithTarget:
        self.progressIndicatorTwo
        selector:@selector(stopAnimation:) object:nil
    ];
    [self.progressIndicatorOne stopAnimation:nil];
    [self.progressIndicatorTwo stopAnimation:nil];
    
    NSString * keyword = [sender stringValue];
    
    if (keyword.length > 0)
    {
        NSMutableString * query = [NSMutableString string];

        switch (self.searchType)
        {
            case 1:
            {
                [query appendFormat:@"%@=%@", keyword, keyword];
            }
            break;
            case 2:
            {
                [query appendFormat:@"u=%@", keyword];
            }
            break;
            default:
            break;
        }
        
        NSLog(@"Searching for %@.", query);
        
        [self.progressIndicatorOne startAnimation:nil];
        [self.progressIndicatorTwo startAnimation:nil];
        
        [self.progressIndicatorOne performSelector:
            @selector(stopAnimation:) withObject:nil afterDelay:3.0f
        ];
        [self.progressIndicatorTwo performSelector:
            @selector(stopAnimation:) withObject:nil afterDelay:3.0f
        ];
        
        self.transactionId = [
            self.messageViewController search:query clearCurrent:YES
        ];
    }
}

- (IBAction)clear:(id)sender
{
    FNAppDelegate * delegate = [NSApp delegate];
    
    [delegate goHome:nil];

    self.searchField.stringValue = @"";

    [self.messageViewController.messages removeAllObjects];

    [self.messageViewController performSelector:@selector(resetGroups)];
    
    [self.messageViewController.tableView reloadData];
}

#pragma mark -

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    if (self.searchField.stringValue.length == 0)
    {
        //NSLog(@"controlTextDidEndEditing: %@", aNotification);
    }
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.tag == self.searchType)
    {
        menuItem.state = NSOnState;
    }
    else
    {
        menuItem.state = NSOffState;
    }
    
    return YES;
}

@end
