//
//  AppDelegate.m
//  Remoter
//
//  Created by Zhengni on 13-5-13.
//
//

#import "AppDelegate.h"
#import "ARViewController.h"
#import "VDARLocalizationManager.h"
#import "Server.h"
#import "BrowserServerViewController.h"
#import "SlideBrowserViewController.h"



@implementation AppDelegate
@synthesize window,arView;


//Put your license key given by the ARManager ( http://armanager.vidinoti.com )
#define VDAR_SDK_LICENSE_KEY @"pejrn8ipp0ca9ad4izf0"

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	NSLog(@"Current Device UDID: %@",[[UIDevice currentDevice] uniqueIdentifier]);
	
    
	NSString *modelDir=[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"models"];
	
	//Required rights for remote model fetching and insertion
	unsigned long featureRight= kVDARRightInsertNewModel | kVDARRightRemoteModelFetch | kVDARRightSendVisualClickNotifications | kVDARRightImageRecognition | kVDARRightAnnotationJSRendering;
	
    
	if(![VDARModelManager startManager:modelDir withVisionData:[[NSBundle mainBundle] pathForResource:@"visionData.data" ofType:@""] andFeatureRights:featureRight andLicenseKey:VDAR_SDK_LICENSE_KEY]) {
		
		NSLog(@"Error while loading the model manager. Fatal.");
		NSAssert(0,@"Error while loading the model manager. Fatal.");
		exit(1);
	}
	
	[[VDARModelManager sharedInstance].afterLoadingQueue addOperationWithBlock:^(void) {
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[VDARLocalizationManager sharedInstance]; //Start the localization updates
		});
        
	}];	

	
   
    //configure for server
    // UINavigationController *nav = [[UINavigationController alloc]init];
    
    serverBrowserVC = [[BrowserServerViewController alloc]init];
    slideBrowserVC = [[SlideBrowserViewController alloc]init];
    
    
    UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
    serverBrowserVC = [[nav viewControllers]objectAtIndex:0];
   
    
    NSString *type = @"TestingProtocol";
    _server = [[Server alloc] initWithProtocol:type];
    _server.delegate = self;
    NSError *error = nil;
    if(![_server start:&error]) {
        NSLog(@"error = %@", error);
    }
    serverBrowserVC.server = _server;
    
    
        
	
    // Override point for customization after application launch.
	
	application.statusBarHidden=YES; //Hide the status bar for a full impresive AR view.
    
    [self.window addSubview:arView.view];
    [self.window makeKeyAndVisible];
	[UIApplication sharedApplication].idleTimerDisabled=YES;
    return YES;


}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	[[VDARModelManager sharedInstance] saveModels];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	[[VDARLocalizationManager sharedInstance] forceUpdate]; // Force a localization update
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	[[VDARModelManager sharedInstance] saveModels];
    [_server stop];
    [_server stopBrowser];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
}



#pragma mark Server Delegate Methods

- (void)serverRemoteConnectionComplete:(Server *)server {
    NSLog(@"Server Started");
    
    // this is called when the remote side finishes joining with the socket as
    // notification that the other side has made its connection with this side
    
    slideBrowserVC.server = server;
      
    
    [serverBrowserVC.navigationController pushViewController:slideBrowserVC animated:YES];
    [slideBrowserVC.tableView reloadData];
}

- (void)serverStopped:(Server *)server {
    NSLog(@"Server stopped");
    
}

- (void)server:(Server *)server didNotStart:(NSDictionary *)errorDict {
    NSLog(@"Server did not start %@", errorDict);
}

- (void)server:(Server *)server didAcceptData:(NSData *)data {
    //NSLog(@"Server did accept data %@", data);
    
    NSMutableArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSLog(@"array %@",array);
    
    //slideBrowserVC.slides = array;
    //[slideBrowserVC.tableView reloadData];
    
    
}

- (void)server:(Server *)server lostConnection:(NSDictionary *)errorDict {
    NSLog(@"Server lost connection %@", errorDict);
    
}

- (void)serviceAdded:(NSNetService *)service moreComing:(BOOL)more {
    
    [serverBrowserVC.services addObject:service];
    if(!more) {
        [serverBrowserVC.tableView reloadData];
    }
}

- (void)serviceRemoved:(NSNetService *)service moreComing:(BOOL)more {
    
    [serverBrowserVC.services removeObject:service];
    if(!more) {
        [serverBrowserVC.tableView reloadData];
    }
}




- (void)dealloc {    
    [serverBrowserVC release];
    serverBrowserVC = nil;
    [slideBrowserVC release];
    slideBrowserVC = nil;
    [arView release];
    arView = nil;
    
    
    [window release];
    [super dealloc];
}


@end
