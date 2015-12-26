//
//  ARViewController.m
//  Remoter
//
//  Created by Zhengni on 13-5-13.
//
//


#import "ARViewController.h"
#import "MyCameraImageSource.h"
#import "VDARLocalizationManager.h"


@implementation ARViewController
@synthesize imageViewforLost,swipecount,swipeLeftRecognizer,swipeRightRecognizer,imageArray,count,tapRecognizer;
@synthesize server = _server;
@synthesize touchLaser,transparentview;


- (void)dealloc
{
	[camera release];
	camera=nil;
    [imageArray release];
    [tapRecognizer release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - VDARModelManager delegate

-(void)errorOccuredOnModelManager:(NSError *)err {
	[super errorOccuredOnModelManager:err];
	UIAlertView *al=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"The license of the AR technology (Vidinoti) used in this application has expired. Please contact the application publisher with this information.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
	[al show];
	[al release];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    
	if(!camera) {
		camera=[[MyCameraImageSource alloc] init];
		self.imageSender=camera;
		camera.imageReceiver=[VDARModelManager sharedInstance];
	}
   
    swipecount = 1;
    count = swipecount;
    touchLaser = 0;

    UIBarButtonItem *Laser =  [[UIBarButtonItem alloc] initWithTitle:@"Laser"  style:UIBarButtonItemStylePlain  target:self  action:@selector(Laser:)];
    self.navigationItem.rightBarButtonItem = Laser;

    
    [self downloadSlideImg];
    [self addGesture];
    
    //self.view.userInteractionEnabled =YES;
    
	
 }

- (void)viewDidUnload
{
    [super viewDidUnload];
}


- (void)modelDetected:(VDARModel *)model
{
    NSLog(@"modelDetected");
    [imageViewforLost removeFromSuperview];
    
}

- (void)modelLost:(VDARModel *)model
{
    NSLog(@"modelLost");
    [self addSubView];
    
    
}



-(void)addGesture
{
    
    swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc]
                           initWithTarget:self action:@selector(handleGesture:)];
    swipeLeftRecognizer.direction = (UISwipeGestureRecognizerDirectionLeft);
    [self.view addGestureRecognizer:swipeLeftRecognizer];
    [swipeLeftRecognizer release];
    
    
    
    swipeRightRecognizer = [[UISwipeGestureRecognizer alloc]
                            initWithTarget:self action:@selector(handleGesture:)];
    swipeRightRecognizer.direction = (UISwipeGestureRecognizerDirectionRight);
    [self.view addGestureRecognizer:swipeRightRecognizer];
    [swipeRightRecognizer release];
    
}



- (void) downloadSlideImg
{
    //to realize
    
}

- (void)addSubView
{
  
    UIImage *image = [UIImage imageNamed:@"test.jpg"]; //do fake image
    
    
    imageViewforLost = [[UIImageView alloc] initWithImage:image];
    imageViewforLost.frame = CGRectMake(0,50,320,200);
  
    
    imageViewforLost.image = [self drawText:[NSString stringWithFormat:@"Current page is %d, swipe to change",swipecount]
                                    inImage:image
                                    atPoint:CGPointMake(0, 0)];
    imageViewforLost.hidden = NO;
    
        
    [self.view addSubview:imageViewforLost];
    imageViewforLost.userInteractionEnabled = YES;

    
}


- (IBAction)handleGesture:(UISwipeGestureRecognizer *)sender{
    
    NSLog(@"Swipe received.");
    
    if ( sender.direction == UISwipeGestureRecognizerDirectionRight)
    {
        swipecount=swipecount-1;
    }
    else
    {
        swipecount=swipecount+1;
        
    }
    
    
    NSString *message = [[NSString alloc] initWithFormat:
                         @"Current page is %d",swipecount];  //upload swipecount
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Page Selected!"
                          message:message
                          delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    
    [alert show];
    [alert release];
    
    
    
    
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //can be called
    [self sendtoServer:swipecount];
    
}

- (void) sendtoServer:(int)uploadnumber{
    //NSLog(@"last number %d",count);
    //NSLog(@"current number %d",uploadnumber);
    
    if (uploadnumber > count) {
        NSString *num = [NSString stringWithFormat:@"%d",1]; //if the end, will jump out of the presentation show
        NSLog(@"forward");
        
        NSData *data = [num dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;

        
        [self.server sendData:data error:&error];
    }
    else if (uploadnumber < count)
    {
        NSString *num = [NSString stringWithFormat:@"%d",-1]; //if already the beginning...now response, won't crash. 
        NSLog(@"backward");
        
        NSData *data = [num dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
       
        [self.server sendData:data error:&error];
    }
    
    count=swipecount;
}

- (UIImage*) drawText:(NSString*) text inImage:(UIImage*) image atPoint:(CGPoint) point
{
    
    UIFont *font = [UIFont boldSystemFontOfSize:25];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    [[UIColor whiteColor] set];
    [text drawInRect:CGRectIntegral(rect) withFont:font];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (IBAction)Laser:(id)sender
{
    NSLog(@"touch %d",touchLaser);
        
    //work only if imageviewforlost shows,in static mode
    if (imageViewforLost != NULL) {
    
    if (touchLaser%2==0) {
        
        touchLaser = touchLaser +1;
        imageViewforLost.userInteractionEnabled = YES;
        
        //important for tap gesture. maybe duplicate
        
        tapRecognizer = [[UITapGestureRecognizer alloc]
                         initWithTarget:self action:@selector(tapGesture:)];
        tapRecognizer.numberOfTapsRequired =1;
        [imageViewforLost addGestureRecognizer:tapRecognizer];
    }
    else
    {
        touchLaser = touchLaser +1;
        //send to mac to delete transparent view and laser point
        NSString *num = [NSString stringWithFormat:@"removelaser"];
                
        NSData *canceldata = [num dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        
        [self.server sendData:canceldata error:&error];
       [imageViewforLost removeGestureRecognizer:tapRecognizer];

    }
    
       
    }
    
}


- (IBAction)tapGesture:(UITapGestureRecognizer *)sender{
    //send data to mac
    CGPoint location = [sender locationInView:[sender.view superview]];
    NSString *coordinate =NSStringFromCGPoint(location);
    
    NSData *locationdata = [coordinate dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;    
    [self.server sendData:locationdata error:&error];
    
}

@end
