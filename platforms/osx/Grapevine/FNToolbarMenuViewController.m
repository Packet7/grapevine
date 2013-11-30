//
//  FNToolbarMenuViewController.m
// Grapevine
//
//  Created by Packet7, LLC. on 7/17/13.
//  Copyright (c) 2013 Packet7, LLC.. All rights reserved.
//

#import "FNSidebarTableRowView.h"
#import "FNToolbarMenuViewController.h"

@interface FNToolbarMenuViewController ()
@property (assign) IBOutlet NSTableView * tableView;
@end

@implementation FNToolbarMenuViewController

- (id)init
{
    self = [super initWithNibName:@"ToolbarMenuView" bundle:[NSBundle mainBundle]];
    
    if (self)
    {
        // ...
    }
    
    return self;
}

- (void)awakeFromNib
{
    self.tableView.backgroundColor = [NSColor windowBackgroundColor];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 2;
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(NSInteger)rowIndex
{
    switch (rowIndex) {
      case 0:
        return NSLocalizedString(@"Post", nil);
        break;
      case 1:
        return NSLocalizedString(@"Search", nil);
        break;
      default:
        break;
    }
    
    return nil;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row 
{
    FNSidebarTableRowView * view = [[FNSidebarTableRowView alloc]
        initWithFrame:NSZeroRect
    ];

    return view;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self.tableView deselectAll:nil];
}

@end
