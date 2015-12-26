//
//  MyCameraImageSource.h
//  VDARSDK
//
//  Created by Mathieu Monney on 04.07.11.
//  Updated on 30.09.2011.
//
//  Copyright 2010-2011 Vidinoti SA. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

#import <VDARSDK/VDARSDK.h>

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

@interface MyCameraImageSource : NSObject<VDARImageSender
#if !TARGET_IPHONE_SIMULATOR && !defined(USE_FIXED_IMAGE)
,AVCaptureVideoDataOutputSampleBufferDelegate
#endif
>
{
	UIInterfaceOrientation videoOrientation;
	
#if TARGET_IPHONE_SIMULATOR || defined(USE_FIXED_IMAGE)
	NSTimer *tmrImageDelivery;
	UIDeviceOrientation orientation;

	uint8_t *simulatorFramePlaneY;
	uint8_t *simulatorFramePlaneUV;
	size_t simulatorFramePlaneWidth[2];
	size_t simulatorFramePlaneHeight[2];
	size_t simulatorFramePlaneBytesPerRow[2];
	void *simulatorFramePlane[2];
	unsigned simulatorWidth,simulatorHeight;
	CVPixelBufferRef pixelBuffer;

	AVAssetReaderTrackOutput *assetReaderOutput;
	AVAssetReader *assetReader;
	dispatch_queue_t dispatchQueue;
	
#else
	AVCaptureSession *captureSession;
	dispatch_queue_t processingQueue;
	AVCaptureVideoDataOutput *videoOut;
	AVCaptureDevice *videoDevice;	
	AVCaptureDeviceInput *videoIn;
#endif
	BOOL started;
}

/** The receiver of the camera frames */
@property (nonatomic,assign) id<VDARImageReceiver> imageReceiver;

/** 
 The frame rate of the camera. 
 
 Can be adjusted to a lower value if the device is not powerful enough to keep up the framerate. 
 Usually a value betweek 20-25 (fps) works correctly.
 */
@property (nonatomic) unsigned int frameRate;

/** Start the image stream */
-(void)startImageStream;

/** Strop the image stream */
-(void)stopImageStream;
@end
