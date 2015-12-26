//
//  MacNetworkingTestingAppDelegate.m
//  MacNetworkingTesting
//
//  Created by Brad Larson on 3/16/2010.
//

#import "MacNetworkingTestingAppDelegate.h"

@implementation MacNetworkingTestingAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	self.message = @"Message";
	connectedRow = -1;
	self.services = [[NSMutableArray alloc] init];
	
	NSString *type = @"TestingProtocol";

	_server = [[Server alloc] initWithProtocol:type];
    _server.delegate = self;

    NSError *error = nil;
    if(![_server start:&error]) {
        NSLog(@"error = %@", error);
    }	
}

- (void)dealloc
{
	[_server release];
	[_services release];
	[_message release];
	[super dealloc];
}

#pragma mark -
#pragma mark Interface methods

- (IBAction)connectToService:(id)sender;
{
	[self.server connectToRemoteService:[self.services objectAtIndex:selectedRow]];
}

- (IBAction)sendText:(id)sender;
{
	NSData *data = [textToSend dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	[self.server sendData:data error:&error];
	
}

#pragma mark -
#pragma mark Server delegate methods

- (void)serverRemoteConnectionComplete:(Server *)server 
{
    NSLog(@"Connected to service");
	
	self.isConnectedToService = YES;

	connectedRow = selectedRow;
	[tableView reloadData];
}

- (void)serverStopped:(Server *)server 
{
    NSLog(@"Disconnected from service");

	self.isConnectedToService = NO;

	connectedRow = -1;
	[tableView reloadData];
}

- (void)server:(Server *)server didNotStart:(NSDictionary *)errorDict 
{
    NSLog(@"Server did not start %@", errorDict);
}

- (void)server:(Server *)server didAcceptData:(NSData *)data 
{
    NSLog(@"Server did accept data %@", data);
    NSString *message = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    if(nil != message || [message length] > 0) {
        self.message = message;
    } else {
        self.message = @"no data received";
    }
}

- (void)server:(Server *)server lostConnection:(NSDictionary *)errorDict 
{
	NSLog(@"Lost connection");
	
	self.isConnectedToService = NO;
	connectedRow = -1;
	[tableView reloadData];
}

- (void)serviceAdded:(NSNetService *)service moreComing:(BOOL)more 
{
	NSLog(@"Added a service: %@", [service name]);
	
    [self.services addObject:service];
    if(!more) {
        [tableView reloadData];
    }
}

- (void)serviceRemoved:(NSNetService *)service moreComing:(BOOL)more 
{
	NSLog(@"Removed a service: %@", [service name]);
	
    [self.services removeObject:service];
    if(!more) {
        [tableView reloadData];
    }
}

#pragma mark -
#pragma mark NSTableView delegate methods

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (rowIndex == connectedRow)
		[aCell setTextColor:[NSColor redColor]];
	else
		[aCell setTextColor:[NSColor blackColor]];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	return [[self.services objectAtIndex:rowIndex] name];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	NSLog(@"Count: %d", [self.services count]);
    return [self.services count];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
	selectedRow = [[aNotification object] selectedRow];
}

#pragma mark -
#pragma mark Accessors

@synthesize server = _server;
@synthesize services = _services;
@synthesize message = _message;
@synthesize isConnectedToService;


@end
