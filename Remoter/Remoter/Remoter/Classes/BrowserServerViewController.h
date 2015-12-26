//
//  BrowserServerViewController.h
//  Remoter
//
//  Created by Zhengni on 13-5-20.
//
//

#import <UIKit/UIKit.h>
#import "Server.h"

@class SlideBrowserViewController;

@interface BrowserServerViewController : UITableViewController
{   Server *_server;
	NSMutableArray *_services;

    
}

@property(nonatomic, retain) Server *server;
@property(nonatomic, retain) NSMutableArray *services;


@end
