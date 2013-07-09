//
//  MasterViewController.h
//  MasterDetailSample
//
//  Created by PraveenKumar Vasudevan on 6/28/13.
//  Copyright (c) 2013 Amada Co Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

-(IBAction)cancel:(UIStoryboardSegue*)sender;
-(IBAction)save:(UIStoryboardSegue*)sender;

@end
