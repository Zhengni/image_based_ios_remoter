//
//  ARViewController.h
//  Remoter
//
//  Created by Zhengni on 13-5-13.
//
//

#import <UIKit/UIKit.h>
#import "Server.h"

@class MyCameraImageSource;


@interface ARViewController : VDARLiveAnnotationViewController{
    MyCameraImageSource *camera;
    UIImageView *imageViewforLost;
    
    int swipecount;
    int count;
    NSMutableArray *imageArray;
    
    Server *_server;
    
    int touchLaser;
    UIImageView *transparentview;
  
    
}


- (UIImage*) drawText:(NSString*) text inImage:(UIImage*) image atPoint: (CGPoint)point;

//for swipe forward/backward presentation
@property (nonatomic, retain) IBOutlet UIImageView *imageViewforLost;
@property (nonatomic) int swipecount;
@property (nonatomic) int count;

//for imageDownload. to realize
@property (nonatomic,retain) NSMutableArray *imageArray;

//for gesture recognizer
@property (nonatomic,strong) IBOutlet UISwipeGestureRecognizer *swipeLeftRecognizer;
@property (nonatomic,strong) IBOutlet UISwipeGestureRecognizer *swipeRightRecognizer;
@property (nonatomic,strong) IBOutlet UITapGestureRecognizer *tapRecognizer;

@property (nonatomic, retain) Server *server;

//for laser function
@property (nonatomic) int touchLaser;
@property (nonatomic, retain) UIImageView *transparentview;
@end
