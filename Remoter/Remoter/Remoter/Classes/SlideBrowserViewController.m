//
//  SlideBrowserViewController.m
//  Remoter
//
//  Created by Zhengni on 13-5-20.
//
//
#import "SlideBrowserViewController.h"
#import "ARViewController.h"

@interface SlideBrowserViewController ()

@end

@implementation SlideBrowserViewController
@synthesize slides;
@synthesize arView;



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];  //if here problem
    self.title = @"Slide";
    self.slides = [[NSMutableArray alloc]initWithObjects:@"Final Prez.pptx", nil];
    [self.tableView reloadData];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.slides count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Slide";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSLog(@"reload");
    cell.text = [self.slides objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *selected = [self.slides objectAtIndex:indexPath.row];
    
    NSData *data = [selected dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    
	[self.server sendData:data error:&error];  

    //push to arview here
    arView = [[ARViewController alloc]init];
    arView.server = self.server;
    [self.navigationController pushViewController:arView animated:YES];
    
}

- (void)dealloc {
    self.slides = nil;
    self.server = nil;
    [super dealloc];
}


@end
