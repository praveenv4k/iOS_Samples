//
//  AddViewController.m
//  MasterDetailSample
//
//  Created by PraveenKumar Vasudevan on 7/9/13.
//  Copyright (c) 2013 Amada Co Ltd. All rights reserved.
//

#import "AddViewController.h"

@interface AddViewController ()

@end

@implementation AddViewController

@synthesize firstNameField=_firstNameField;
@synthesize lastNameField=_lastNameField;
@synthesize organizationField=_organizationField;
@synthesize phoneNumberField=_phoneNumberField;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Add View Controller : View Did Load Called");
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"Add View Controller : didReceiveMemoryWarning Called");
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    if ((textField == self.firstNameField) ||
        (textField == self.lastNameField) || (textField == self.phoneNumberField) ||
        (textField == self.organizationField)) {
        
        NSLog(@"Resigning First Responder");
        [textField resignFirstResponder];
    }
    return YES;
}

@end
