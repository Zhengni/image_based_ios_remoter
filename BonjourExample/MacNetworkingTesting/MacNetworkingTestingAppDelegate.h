//
//  MacNetworkingTestingAppDelegate.h
//  MacNetworkingTesting
//
//  Created by Brad Larson on 3/16/2010.
//

#import <Cocoa/Cocoa.h>
#import "Server.h"

@interface MacNetworkingTestingAppDelegate : NSObject <NSApplicationDelegate, ServerDelegate> 
{
	IBOutlet NSTableView *tableView;
    NSWindow *window;
	Server *_server;
	NSMutableArray *_services;
	NSString *textToSend, *_message;
	NSInteger selectedRow, connectedRow;
	BOOL isConnectedToService;
}

@property (assign) IBOutlet NSWindow *window;
@property(nonatomic, retain) Server *server;
@property(nonatomic, retain) NSMutableArray *services;
@property(readwrite, copy) NSString *message;
@property(readwrite, nonatomic) BOOL isConnectedToService;

// Interface methods
- (IBAction)connectToService:(id)sender;
- (IBAction)sendText:(id)sender;

@end
