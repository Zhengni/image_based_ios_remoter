//
//  MacNetworkingTestingAppDelegate.m
//  MacNetworkingTesting
//
//  Created by Brad Larson on 3/16/2010.
//

#import "MacNetworkingTestingAppDelegate.h"


@implementation MacNetworkingTestingAppDelegate

@synthesize window,ParentURL;
@synthesize overlayWindow,view;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
    [self.window setLevel:NSScreenSaverWindowLevel]; 
    [self.window orderBack:self];
    
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
    [self searchFile];  //wait too long, to improve
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
    
    if ([message isEqual: @"1"]) {
        NSString *forward = [NSString stringWithFormat:@"tell application \"Microsoft PowerPoint\" \n go to next slide slide show view of slide show window 1 \n end tell \n"];
        
        NSDictionary *errorInfo = nil;
        NSAppleScript *script = [[NSAppleScript alloc] initWithSource:forward];
        [script executeAndReturnError:&errorInfo];
        [script release];
        
    }
    else if([message isEqual: @"-1"])
    {
        NSString *backward = [NSString stringWithFormat:@"tell application \"Microsoft PowerPoint\" \n go to previous slide slide show view of slide show window 1 \n end tell \n"];
        
        NSDictionary *errorInfo = nil;
        NSAppleScript *script = [[NSAppleScript alloc] initWithSource:backward];
        [script executeAndReturnError:&errorInfo];
        [script release];

        //the script could be change to any applescript. 
        
    }
    else if([message rangeOfString:@"ppt"].location!=NSNotFound) //contain filename extension
    {
        NSString *SlideURL = [NSString stringWithFormat:@"%@/%@",ParentURL,self.message];
        [self startScript:SlideURL];
        [self downloadImg:self.message];

    }
    else if([message rangeOfString:@"removelaser"].location!=NSNotFound)
    {
        
        [view removeFromSuperview];
        [self.window removeChildWindow:overlayWindow];
        
        
    }

    else
    {
        //laser point
        //check the message from mac app
        NSPoint cordinate = NSPointFromString(message);
        [self laser:cordinate];
        
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



- (void)searchFile
{
    NSLog(@"called");

    NSString *URL = [[NSBundle mainBundle] bundlePath];  //return current URL
    
    //DELETE THE LAST ITEM TO GET THE PARENT FOLDER
    ParentURL = [URL stringByDeletingLastPathComponent];
    NSLog(@"file%@",URL);
    
    NSMutableArray *array = [[NSMutableArray alloc]init];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray* tempArray = [fileMgr contentsOfDirectoryAtPath:ParentURL error:nil];
    for (NSString *fileName in tempArray) {
        if ([[fileName pathExtension]isEqualToString:@"pptx"]||[[fileName pathExtension]isEqualToString:@"ppt"]) {
            
            BOOL flag = YES;
            NSString *fullPath = [ParentURL stringByAppendingPathComponent:fileName];
            if ([fileMgr fileExistsAtPath:fullPath isDirectory:&flag]) {
                if (!flag) {
                    //[array addObject:fullPath];  //to return fullPath
                    [array addObject:fileName];    //to return only file name
                }
            }
        }
        
    }
    
    NSLog(@"%@",array);
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
    if (data == nil) {
        NSLog(@"nil");
    }
	NSError *error = nil;
    self.message = [NSString stringWithFormat:@"done search"];
	[self.server sendData:data error:&error]; 
    
    // use the array to return the content
}


- (void)startScript:(NSString *)string
{
    NSString *temp = string;
    
    NSString *SlideURL = [NSString stringWithFormat:@"set mypath to \"%@\" \n tell application \"Microsoft PowerPoint\" \n activate \n open mypath \n set temp to slide show settings of active presentation \n run slide show temp \n end tell\n",temp];
    
    NSDictionary *errorInfo = nil;
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:SlideURL];
    [script executeAndReturnError:&errorInfo];
    [script release];

}


- (void)laser:(NSPoint)location
{
    //create top transparentview
    if (overlayWindow == NULL) {
        
    NSRect rect = [[NSScreen mainScreen] frame]; 
    
    // Create a full-screen window
    overlayWindow = [[NSWindow alloc]initWithContentRect:rect
                                                         styleMask:NSBorderlessWindowMask
                                                           backing:NSBackingStoreBuffered
                                                             defer:YES];
    overlayWindow.backgroundColor = [NSColor clearColor];
    [overlayWindow setOpaque:NO];       //not necessary if clearcolor
    [overlayWindow setAlphaValue:0.2];  //not necessary if clearcolor
    [overlayWindow setHasShadow:YES];
    [overlayWindow setLevel:NSScreenSaverWindowLevel];
        
    //if change to nsnormalwindowlevel, won't be on the top of presentation
        
    [overlayWindow orderFront:self];
    [self.window addChildWindow:overlayWindow ordered:NSWindowAbove];
        
        
    }
    
    float height = overlayWindow.frame.size.height;   //1280*800
    float width = overlayWindow.frame.size.width;
    float x = location.x/320*width;
    float y = height-(location.y-50)/200*height;      //depends on the imageviewforlost, static image postion on ios
    
    if (view==NULL) {
        
        //everytime only one point later can change to path
        
        view = [[NSView alloc] initWithFrame:NSMakeRect(x,y, 150, 8)];
        [view setWantsLayer:YES];
        view.layer.backgroundColor = [[NSColor redColor] CGColor];
        [overlayWindow.contentView addSubview:view];
    }
    else
    {
        [view removeFromSuperview];
        view = [[NSView alloc] initWithFrame:NSMakeRect(x,y, 150, 8)];
        [view setWantsLayer:YES];
        view.layer.backgroundColor = [[NSColor redColor] CGColor];
        [overlayWindow.contentView addSubview:view];

        
    }
    

}




-(void)downloadImg:(NSString *)foldername{
    //to realize
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
	NSLog(@"Count: %ld", [self.services count]);
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
