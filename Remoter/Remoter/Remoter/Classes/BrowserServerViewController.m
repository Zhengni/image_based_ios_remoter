//
//  BrowserServerViewController.m
//  Remoter
//
//  Created by Zhengni on 13-5-20.
//
//

#import "BrowserServerViewController.h"

@interface BrowserServerViewController ()

@end

@implementation BrowserServerViewController
@synthesize services = _services;
@synthesize server = _server;


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.services = nil;
    self.title = @"Connection";
    [self.tableView reloadData];
    
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.services = nil;
}

- (NSMutableArray *)services {
    if(nil == _services) {
        self.services = [NSMutableArray array];
    }
    return _services;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Search for Devices";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _services.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.text = [[_services objectAtIndex:indexPath.row] name];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.server connectToRemoteService:[_services objectAtIndex:indexPath.row]];
    
    
}

#pragma mark -

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
    self.services = nil;
    self.server = nil;
    [super dealloc];
}

@end