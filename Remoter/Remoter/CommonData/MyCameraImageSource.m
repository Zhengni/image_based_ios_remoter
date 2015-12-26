//
//  MyCameraImageSource.m
//  VDARSDK
//
//  Created by Mathieu Monney on 04.07.11.
//  Updated on 30.09.2011.
//
//  Copyright 2010-2012 Vidinoti SA. All rights reserved.
//

#import "MyCameraImageSource.h"

@implementation MyCameraImageSource
@synthesize frameRate,imageReceiver;

#if TARGET_IPHONE_SIMULATOR || defined(USE_FIXED_IMAGE)

#define USE_VIDEO 0

static void releaseCallBack( void *releaseRefCon, const void *dataPtr, size_t dataSize, size_t numberOfPlanes, const void *planeAddresses[] ) {

}

-(void)loadSimulatorFrame {

	
	
	if(!simulatorFramePlaneY) {
		simulatorFramePlaneY=(uint8_t*)malloc(VDAR_INPUT_IMAGE_WIDTH*VDAR_INPUT_IMAGE_HEIGHT);
	}
	if(!simulatorFramePlaneUV) {
		simulatorFramePlaneUV=(uint8_t*)malloc(VDAR_INPUT_IMAGE_WIDTH*VDAR_INPUT_IMAGE_HEIGHT/2);
	}
	
	
	simulatorWidth=VDAR_INPUT_IMAGE_WIDTH;
	simulatorHeight=VDAR_INPUT_IMAGE_HEIGHT;
	

	
	
	if(!pixelBuffer) {
		simulatorFramePlaneWidth[0]=VDAR_INPUT_IMAGE_WIDTH;
		simulatorFramePlaneHeight[0]=VDAR_INPUT_IMAGE_HEIGHT;
		simulatorFramePlaneWidth[1]=VDAR_INPUT_IMAGE_WIDTH/2;
		simulatorFramePlaneHeight[1]=VDAR_INPUT_IMAGE_HEIGHT/2;
		simulatorFramePlaneBytesPerRow[0]=VDAR_INPUT_IMAGE_WIDTH;
		simulatorFramePlaneBytesPerRow[1]=VDAR_INPUT_IMAGE_WIDTH;
		
		simulatorFramePlane[0]=simulatorFramePlaneY;
		simulatorFramePlane[1]=simulatorFramePlaneUV;

		CVReturn ret=CVPixelBufferCreateWithPlanarBytes(NULL,VDAR_INPUT_IMAGE_WIDTH,VDAR_INPUT_IMAGE_HEIGHT,kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,NULL,0,2,simulatorFramePlane,simulatorFramePlaneWidth,simulatorFramePlaneHeight,simulatorFramePlaneBytesPerRow,&releaseCallBack,self,NULL,&pixelBuffer);
		
		if(ret!=kCVReturnSuccess) {
			NSLog(@"Unable to create Pixel Buffer");
			pixelBuffer=NULL;
		}
	}
	
#if !USE_VIDEO	
	NSString *imgName;
	
	switch(orientation) {
		case UIDeviceOrientationLandscapeLeft:
			imgName = [NSString stringWithFormat:@"image_left.yuv"];
			break;
		case UIDeviceOrientationLandscapeRight:
			imgName = [NSString stringWithFormat:@"image_right.yuv"];
			break;
		default:
			imgName = [NSString stringWithFormat:@"image.yuv"];
	}
	
	
	
	
	NSString *path=[[NSBundle mainBundle] pathForResource:imgName ofType:@"" inDirectory:@"simulatorImages"];
	
	
	NSData *frameData=[NSData dataWithContentsOfFile:path];
	
	uint32_t width,height;
	
	if([frameData length]<7+2*sizeof(width) || memcmp(frameData.bytes,"VDARYUV",7)!=0) {
		NSAssert(0,@"The simulator YUV image is not of the correct form. Please use the JPEGtoYUV420 tool to convert an image to the correct format.");
		return;
	}
	
	memcpy(&width, frameData.bytes+7, sizeof(width));
	memcpy(&height, frameData.bytes+7+sizeof(width), sizeof(height));
	
	if(width!=VDAR_INPUT_IMAGE_WIDTH || height!=VDAR_INPUT_IMAGE_HEIGHT) {
		NSAssert2(0,@"The simulator YUV image is not of the correct size. Only image of %ux%u is supported.",VDAR_INPUT_IMAGE_WIDTH,VDAR_INPUT_IMAGE_HEIGHT);
		return;
	}
	
	NSAssert2([frameData bytes]+7+2*sizeof(width)+VDAR_INPUT_IMAGE_WIDTH*VDAR_INPUT_IMAGE_HEIGHT+VDAR_INPUT_IMAGE_WIDTH*VDAR_INPUT_IMAGE_HEIGHT/2==[frameData bytes]+[frameData length],@"The input image for simulator must be of size %ux%u and converted to YUV by thr JPEGtoYUV converter tool.",VDAR_INPUT_IMAGE_WIDTH,VDAR_INPUT_IMAGE_HEIGHT);
	
	memcpy(simulatorFramePlaneY,[frameData bytes]+7+2*sizeof(width),VDAR_INPUT_IMAGE_WIDTH*VDAR_INPUT_IMAGE_HEIGHT);
	memcpy(simulatorFramePlaneUV,[frameData bytes]+7+2*sizeof(width)+VDAR_INPUT_IMAGE_WIDTH*VDAR_INPUT_IMAGE_HEIGHT,VDAR_INPUT_IMAGE_WIDTH*VDAR_INPUT_IMAGE_HEIGHT/2);
#else	
	AVURLAsset *avAsset =[AVURLAsset URLAssetWithURL:[[NSBundle mainBundle] URLForResource:@"test_video" withExtension:@"mp4"] options:nil];
	[assetReader cancelReading];
	[assetReader release];
	[assetReaderOutput release];
	assetReaderOutput=nil;
	assetReader=nil;
	
	assetReader = [[AVAssetReader assetReaderWithAsset:avAsset error:nil] retain];
	NSArray *tracks = [avAsset tracksWithMediaType:AVMediaTypeVideo];
						  NSAssert(tracks.count>0,@"The simulator video should have at least one video track.");		  
	AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
	
	NSDictionary *set=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],kCVPixelBufferPixelFormatTypeKey,nil];
	
	assetReaderOutput = [[AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:set] retain];
	if (!assetReaderOutput && ![assetReader canAddOutput:assetReaderOutput]) {
		NSLog(@"Unable to load video for simulator");
		abort();
	}
	[assetReader addOutput:assetReaderOutput];
	

	
#endif
}

#endif

#if !TARGET_IPHONE_SIMULATOR  && !defined(USE_FIXED_IMAGE)
-(BOOL)setupCamera {
	
	NSArray *allDevices=[AVCaptureDevice devices];
	
	for(AVCaptureDevice *dev in allDevices) {
		if(dev.position==AVCaptureDevicePositionBack) {
			videoDevice=[dev retain];
			break;
		}
	}
	
	
	if ( videoDevice ) {
		NSError *error;
		
		if([videoDevice lockForConfiguration:&error]) {
			if([videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
				videoDevice.focusMode=AVCaptureFocusModeContinuousAutoFocus;
			if([videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
				videoDevice.whiteBalanceMode=AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
			if([videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
				videoDevice.exposureMode=AVCaptureExposureModeContinuousAutoExposure;
			[videoDevice unlockForConfiguration];
		} else {
			NSLog(@"Error while locking the camera.");
		}
		
		//Change the preset if not supported on iPad (due to front / back camera)

		if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
			if([videoDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]) {
				captureSession.sessionPreset = AVCaptureSessionPresetMedium; //For future: use AVCaptureSessionPreset1280x720 when scaling is supported
			} else {
				captureSession.sessionPreset = AVCaptureSessionPresetMedium; //To have a 480x360 picture
			}
		} 
		
		
		 videoIn = [[AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error] retain];
		if ( !error ) {
			if ([captureSession canAddInput:videoIn])
				[captureSession addInput:videoIn];
			else{
				UIAlertView *a=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera error",@"") message:NSLocalizedString(@"Unable to connect to the camera.",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",@"") otherButtonTitles:nil];
				[a show];
				[a release];
				return NO;
			}
			self.frameRate=frameRate;
		}
		else{
			UIAlertView *a=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera error",@"") message:[NSString stringWithFormat:NSLocalizedString(@"Unable to connect to the camera: %@.",@""),[error localizedDescription]] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",@"") otherButtonTitles:nil];
			[a show];
			[a release];
			return NO;
		}
	}
	else{
		UIAlertView *a=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera error",@"") message:NSLocalizedString(@"Unable to connect to the camera.",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",@"") otherButtonTitles:nil];
		[a show];
		[a release];
		return NO;
	}
	return YES;
}
-(void)teardownCamera {
	[captureSession removeInput:videoIn];
	[videoIn release];
	[videoDevice release];
	videoDevice=nil;
	videoIn=nil;
}
#else

-(void)orientationChange:(NSNotification*)notif {
	orientation=[UIDevice currentDevice].orientation;
	
	[self loadSimulatorFrame];
	
}

#endif
-(id)init {
	if((self = [super init])) {
		started=NO;
		
#if !TARGET_IPHONE_SIMULATOR && !defined(USE_FIXED_IMAGE)
		captureSession = [[AVCaptureSession alloc] init];
		
		
		//If we have an ipad, we will use a higher quality video and downscale it in live
		
		if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
			captureSession.sessionPreset = AVCaptureSessionPresetMedium; //For future use: AVCaptureSessionPreset1280x720
		} else {
			captureSession.sessionPreset = AVCaptureSessionPresetMedium; //To have a 480x360 picture
		}
		
	
		processingQueue = dispatch_queue_create("com.MyCompany.MyCameraImageSource.ProcessingQueue", NULL);
	
		videoOut = [[AVCaptureVideoDataOutput alloc] init];
		[videoOut setAlwaysDiscardsLateVideoFrames:YES];
		[videoOut setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]]; // BGRA is necessary for manual preview


		[videoOut setSampleBufferDelegate:self queue:processingQueue];

		
		if ([captureSession canAddOutput:videoOut])
			[captureSession addOutput:videoOut];
		else{
			UIAlertView *a=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera error",@"") message:NSLocalizedString(@"Unable to connect to the camera.",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",@"") otherButtonTitles:nil];
			[a show];
			[a release];
			[self release];
			return nil;
		}


#endif
	
#if TARGET_IPHONE_SIMULATOR  || defined(USE_FIXED_IMAGE)
		dispatchQueue=dispatch_queue_create("com.MyCompany.MyCameraImageSource.ProcessingQueue", NULL);
		orientation=[UIDevice currentDevice].orientation;
		//Register for notification to rotate frame
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
		
		//Load fixed frame
		[self loadSimulatorFrame];
#endif
		
		if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
			self.frameRate=30;
		} else {
			self.frameRate=22; //Default frame rate (i.e. 25 fps)
		}
		
		
		
		
	}
	return self;
}

#if TARGET_IPHONE_SIMULATOR || defined(USE_FIXED_IMAGE)

-(void)tmrNewFrame {
	
#if USE_VIDEO	
	if(assetReader.status!=AVAssetReaderStatusReading) 
		return;
	
	//Dispatch it on a thread
	CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
	
	if(nextBuffer==NULL) {
		[self loadSimulatorFrame];
		[assetReader startReading];
		return;
	}
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(nextBuffer);
	CFRetain(nextBuffer); 
#endif
	
	dispatch_async(dispatchQueue, ^{
#if !USE_VIDEO
		[imageReceiver didCaptureFrame:pixelBuffer atTimestamp:0];
#else
		//Convert to the right buffer format
		size_t bufferHeight = CVPixelBufferGetHeightOfPlane(imageBuffer,0);
		size_t bufferWidth = CVPixelBufferGetWidthOfPlane(imageBuffer,0);
		

		size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,1);

		size_t bufferHeight2 = CVPixelBufferGetHeightOfPlane(imageBuffer,1);
		size_t bufferWidth2 = CVPixelBufferGetWidthOfPlane(imageBuffer,1);
		
		
		size_t bytesPerRow2 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,1);
		
		assert(bufferWidth==VDAR_INPUT_IMAGE_WIDTH && bufferHeight==VDAR_INPUT_IMAGE_HEIGHT);
		assert(bufferWidth2==VDAR_INPUT_IMAGE_WIDTH/2 && bufferHeight2==VDAR_INPUT_IMAGE_HEIGHT/2);
		
		if(bufferWidth!=bytesPerRow || bufferWidth2!=bytesPerRow2) {
			//Convert to the right format
			CVPixelBufferLockBaseAddress(imageBuffer, 0);
			uint8_t *rowBase = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
			
			for(size_t y=0;y<bufferHeight;y++) {
				memcpy(simulatorFramePlaneY+y*VDAR_INPUT_IMAGE_WIDTH, rowBase+y*bytesPerRow, VDAR_INPUT_IMAGE_WIDTH);
			}
			rowBase = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,1);
			
			for(size_t y=0;y<bufferHeight2;y++) {
				memcpy(simulatorFramePlaneUV+y*VDAR_INPUT_IMAGE_WIDTH, rowBase+y*bytesPerRow2, VDAR_INPUT_IMAGE_WIDTH);
			}

			CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
			[imageReceiver didCaptureFrame:pixelBuffer atTimestamp:0];
		} else {
			[imageReceiver didCaptureFrame:imageBuffer atTimestamp:0];
		}
		
		
		CFRelease(nextBuffer);
#endif
	});
}
#else
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );

	[imageReceiver didCaptureFrame:pixelBuffer atTimestamp:0];
}
#endif

-(void)setFrameRate:(unsigned int)f {
	
	NSAssert([NSThread mainThread]==[NSThread currentThread],@"setFrameRate: should be called on the main thread!");
	
	frameRate=f;
#if TARGET_IPHONE_SIMULATOR ||  defined(USE_FIXED_IMAGE)
	[tmrImageDelivery invalidate];
	[tmrImageDelivery release];
	tmrImageDelivery = [[NSTimer timerWithTimeInterval:1.0/frameRate target:self selector:@selector(tmrNewFrame) userInfo:nil repeats:YES] retain];
	if(started) {
		[[NSRunLoop currentRunLoop] addTimer:tmrImageDelivery forMode:NSDefaultRunLoopMode]; 
	}
#else
	if([videoOut respondsToSelector:@selector(connectionWithMediaType:)]) {
		AVCaptureConnection *conn = [videoOut connectionWithMediaType:AVMediaTypeVideo];
		if(conn) {
			if ([conn respondsToSelector:@selector(setVideoMinFrameDuration:)] && conn.supportsVideoMinFrameDuration){
				conn.videoMinFrameDuration = CMTimeMake(1,frameRate);
			} else{
				videoOut.minFrameDuration = CMTimeMake(1,frameRate);
			}
			if ([conn respondsToSelector:@selector(setVideoMaxFrameDuration:)] && conn.supportsVideoMaxFrameDuration){
				conn.videoMaxFrameDuration = CMTimeMake(1,frameRate);
			}
		}
	} else {
		videoOut.minFrameDuration=CMTimeMake(1, frameRate);
	}
#endif
}

-(void)startImageStream {
	if(started) return;
#if TARGET_IPHONE_SIMULATOR || defined(USE_FIXED_IMAGE)
	if(!tmrImageDelivery)
		tmrImageDelivery = [[NSTimer timerWithTimeInterval:1.0/frameRate target:self selector:@selector(tmrNewFrame) userInfo:nil repeats:YES] retain];
#if USE_VIDEO
	assetReader.timeRange=CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
	[assetReader startReading];
#endif
	[[NSRunLoop currentRunLoop] addTimer:tmrImageDelivery forMode:NSDefaultRunLoopMode]; 
#else
	[self setupCamera];
	[captureSession startRunning];
#endif
	started=YES;
}

-(void)stopImageStream {
	if(!started) return;
#if TARGET_IPHONE_SIMULATOR || defined(USE_FIXED_IMAGE)
	[tmrImageDelivery invalidate];
	[tmrImageDelivery release];
	tmrImageDelivery=nil;
#if USE_VIDEO
	[assetReader cancelReading];
#endif
#else
	[captureSession stopRunning];
	[self teardownCamera];
#endif
	started=NO;
}
-(void)dealloc {
	self.imageReceiver=nil;
	[self stopImageStream];
#if TARGET_IPHONE_SIMULATOR || defined(USE_FIXED_IMAGE)
	[tmrImageDelivery invalidate];
	[tmrImageDelivery release];

	if(pixelBuffer)
		CVPixelBufferRelease(pixelBuffer);
	pixelBuffer=NULL;
	
	if(simulatorFramePlaneY)
		free(simulatorFramePlaneY);
	if(simulatorFramePlaneUV)
		free(simulatorFramePlaneUV);
	simulatorFramePlaneUV=NULL;
	simulatorFramePlaneY=NULL;

	[assetReader release];
	[assetReaderOutput release];
	dispatch_release(dispatchQueue);
#else
	[captureSession release];
	captureSession=nil;

	dispatch_release(processingQueue);
	processingQueue=nil;

	[videoOut release];
	videoOut=nil;
	[videoDevice release];
	videoDevice=nil;
	[videoIn release];
	videoIn=nil;
#endif

	[super dealloc];
}

-(CGSize)cameraImageSize {
	return CGSizeMake(VDAR_INPUT_IMAGE_WIDTH, VDAR_INPUT_IMAGE_HEIGHT);
}

@end
