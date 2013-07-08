//
//  EditViewController.m
//  MasterDetailSample
//
//  Created by PraveenKumar Vasudevan on 6/30/13.
//  Copyright (c) 2013 Amada Co Ltd. All rights reserved.
//

#import "EditViewController.h"
#import "Person.h"

@interface EditViewController ()

@end

@implementation EditViewController

@synthesize detailItem = _detailItem;
@synthesize firstNameField = _firstNameField;
@synthesize lastNameField = _lastNameField;
@synthesize phoneNumberField = _phoneNumberField;
@synthesize organizationField = _organizationField;

-(void) setDetailItem:(id)detailItem{
    if(_detailItem!=detailItem){
        _detailItem = detailItem;
        [self configureView];
    }
}

-(void)configureView{
    if(self.detailItem && [self.detailItem isKindOfClass:[Person class]]){
        self.firstNameField.text = [self.detailItem firstName];
        self.lastNameField.text = [self.detailItem lastName];
        self.organizationField.text = [self.detailItem organization];
        self.phoneNumberField.text = [self.detailItem phoneNumber];
    }
}

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
    [self configureView];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    if ((textField == self.firstNameField) ||
        (textField == self.lastNameField) || (textField == self.phoneNumberField) ||
        (textField == self.organizationField)) {
        [textField resignFirstResponder]; }
    return YES;
}

@end
