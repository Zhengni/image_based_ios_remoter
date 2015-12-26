//
//  AppDelegate.h
//  Remoter
//
//  Created by Zhengni on 13-5-13.
//
//

#import <UIKit/UIKit.h>
#import "VDARSDK/VDARModelManager.h"
#import "ARViewController.h"
#import "Server.h"

@class BrowserServerViewController;
@class SlideBrowserViewController;
@class ARViewController;



@interface AppDelegate : NSObject <UIApplicationDelegate, VDARModelManagerDelegate,ServerDelegate> {
    UIWindow *window;
    Server *_server;
    BrowserServerViewController *serverBrowserVC;
    SlideBrowserViewController *slideBrowserVC;
    ARViewController *arView;



}




@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) ARViewController *arView;


@end

