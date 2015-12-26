//
//  VDARLocalizationManager.m
//  VDARSDK
//
//  Created by Laurent Rime on 5/30/11.
//  Copyright 2011 Vidinoti SA. All rights reserved.
//

#import "VDARLocalizationManager.h"

#import "NSTimer+Blocks.h"


//Setting this macro to one will simulate a GPS position.
//The position will alternate between Lausanne (Switzerland) and Fribourg (Switzerland)
//You can change this position on the below code.
#define POSITION_SIMULATION 0


#define MIN_DISTANCE_UPDATE 10 // in meters. Minimum movement to update GPS position

// The radius used by Vidinoti servers to search for AR Model around the given GPS position (in meters)
#define SEARCH_RADIUS 500

static VDARLocalizationManager* sharedInstance=NULL;

@interface VDARLocalizationManager()
-(void) updateModels;

@end


// Modified by juydjung
@interface VDARTagPrior()
@end

@implementation VDARLocalizationManager

@synthesize localizationPrior,hasPositionForVDARSDK,positionPrecision,tagPrior;


- (id)init {
    if((self=[super init])) {
		
        isUpdating = NO;
        hasPositionForVDARSDK=NO;
        positionSimulationSwitch=0;
        timerPosition = nil;
        positionPrecision=1e10;
        localizationPrior = [[VDARLocalizationPrior alloc] init];
        

        tagPrior = [[VDARTagPrior alloc] init];
        tagPrior.tagName = @"remoter";
		
		
#if POSITION_SIMULATION==0	
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter = MIN_DISTANCE_UPDATE;
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters; // 10 m
        [locationManager startUpdatingLocation];
#else
		timerPosition=[[NSTimer scheduledTimerWithTimeInterval:10 repeats:YES usingBlock:^(NSTimer *timer)  {
			
			// Fribourg, carrière 26
			// 46.803210, 7.145198
			
			// Lausanne, BC344
			// 46.518232, 6.561772
			
			localizationPrior.searchDistance=SEARCH_RADIUS;
			positionPrecision=SEARCH_RADIUS;
			hasPositionForVDARSDK=YES;
			switch (positionSimulationSwitch) {
				case 0: // Fribourg
					localizationPrior.latitude = 46.803210;
					localizationPrior.longitude = 7.145198;
					NSLog(@"Using simulated GPS Position: Fribourg");
					break;
					
				case 1: // Lausanne
					localizationPrior.latitude = 46.518232;
					localizationPrior.longitude = 6.561772;
					NSLog(@"Using simulated GPS Position: Lausanne");
					
					break;
					
				default:
					break;
			}
			
			[self updateModels];
			positionSimulationSwitch=!positionSimulationSwitch;
		} ] retain];	
#endif
		
        
    }
    
    return self;
}

-(void)forceUpdate {
	if(hasPositionForVDARSDK) {
		[self updateModels];
	}
}

-(void)dealloc {
#if POSITION_SIMULATION==1	
	[timerPosition invalidate];
	[timerPosition release];
	timerPosition=nil;
#else
	[locationManager stopUpdatingLocation];
    [locationManager release];
	locationManager=nil;
#endif
    [localizationPrior release];
    [tagPrior release];
    [super dealloc];
}

-(void) updateModels {
	NSAssert([NSThread currentThread]==[NSThread mainThread],@"Can be called only from main thread.");
	
	if(isUpdating) {
		nbUpdateToDo++;
		return;
	}
	
	dispatch_block_t blockUpdate=^(void) {
        // Modified by judyjung
		// NSArray * priors =[NSArray arrayWithObject:localizationPrior];
        NSArray * priors = [NSArray arrayWithObject:tagPrior];
		
		
		if(!isUpdating){
			isUpdating= true;
			
			//Synchronize the local DB with those tags. The old models which are not anymore needed will be automatically deleted.
			[[VDARRemoteController sharedInstance] syncRemoteModelsAsynchronouslyWithPriors:priors withCompletionBlock:^(id result, NSError *err) {
                
                // Modified by judyjung
				//NSLog(@"Vidinoti AR System got the following model for position %f %f: %@",localizationPrior.latitude,localizationPrior.longitude,result);
                NSLog(@"Vidinoti AR System got the following model for tag %@ %@",tagPrior.tagName, result);
               
                
				if(err)
					NSLog(@"The system got an error: %@",err);
				
				isUpdating = false;
				
				if(nbUpdateToDo>0) { //Another update has to be scheduled, we could issue nbUpdateToDo updates but it would block the user interface a lot...
					nbUpdateToDo=0;
					[self performSelectorOnMainThread:@selector(updateModels) withObject:nil waitUntilDone:NO];
				}
			}];
		}
	};
	
	if([VDARModelManager sharedInstance].dbLoaded) {
		blockUpdate();
	} else {
		
		[[VDARModelManager sharedInstance].afterLoadingQueue addOperationWithBlock:^(void) {
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				blockUpdate();
			});
			
		}];	
		
	}
	
	
	
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    float latitude = newLocation.coordinate.latitude;
    float longitude = newLocation.coordinate.longitude;
    
    
	
	localizationPrior.latitude = latitude;
	localizationPrior.longitude = longitude;
	localizationPrior.searchDistance=MAX(SEARCH_RADIUS,newLocation.horizontalAccuracy);
	hasPositionForVDARSDK=YES;
	positionPrecision=newLocation.horizontalAccuracy;
	
    [self updateModels];
    
}


#pragma mark -
#pragma mark Singleton methods

+ (VDARLocalizationManager*)sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
			sharedInstance = [[VDARLocalizationManager alloc] init];
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

- (oneway void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}




@end
