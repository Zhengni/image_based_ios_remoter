//
//  SlideBrowserViewController.h
//  Remoter
//
//  Created by Zhengni on 13-5-20.
//
//

#import <UIKit/UIKit.h>
#import "Server.h"

@class ARViewController;

@interface SlideBrowserViewController : UITableViewController{
    Server *_server;
    NSMutableArray *_slides;
    ARViewController *arView;
    
 
}

@property(nonatomic, retain) Server *server;
@property(nonatomic, retain) NSMutableArray *slides;
@property(nonatomic, retain) ARViewController *arView;



@end
