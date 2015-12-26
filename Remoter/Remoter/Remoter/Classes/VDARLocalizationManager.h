//
//  VDARLocalizationManager.h
//  VDARSDK
//
//  Created by Laurent Rime on 5/30/11.
//  Copyright 2011 Vidinoti SA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

// Modified by judyjung
#import "VDARSDK/VDARTagPrior.h"


@class VDARLocalizationPrior;

@interface VDARLocalizationManager : NSObject <CLLocationManagerDelegate>{
    
    CLLocationManager *locationManager;
    
    bool isUpdating;
    
    int positionSimulationSwitch; // for position simulation

    NSTimer * timerPosition;
    
	//When updateModels is called (internally), only one update can be run at a time. Therefore, this counter count how many updates we have to issue after one is done.
	unsigned int nbUpdateToDo;
}


@property (nonatomic,retain) VDARLocalizationPrior * localizationPrior;

// Modified by judyjung
@property (nonatomic,retain) VDARTagPrior * tagPrior;

@property (nonatomic) BOOL hasPositionForVDARSDK;
@property (nonatomic,readonly) float positionPrecision;

+ (VDARLocalizationManager*)sharedInstance;

-(void)forceUpdate;

@end
