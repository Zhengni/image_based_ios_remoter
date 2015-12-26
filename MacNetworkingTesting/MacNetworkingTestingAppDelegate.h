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
    
    NSString *ParentURL;
    NSWindow *overlayWindow;
    NSView *view;
}

@property (assign) IBOutlet NSWindow *window;
@property(nonatomic, retain) Server *server;
@property(nonatomic, retain) NSMutableArray *services;
@property(readwrite, copy) NSString *message;
@property(readwrite, nonatomic) BOOL isConnectedToService;
@property (nonatomic, retain) NSString *ParentURL;
@property (nonatomic, retain) NSWindow *overlayWindow;
@property (nonatomic, retain) NSView *view;

// Interface methods
- (IBAction)connectToService:(id)sender;
- (IBAction)sendText:(id)sender;

@end
