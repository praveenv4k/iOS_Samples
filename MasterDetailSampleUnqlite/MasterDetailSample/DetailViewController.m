//
//  DetailViewController.m
//  MasterDetailSample
//
//  Created by PraveenKumar Vasudevan on 6/28/13.
//  Copyright (c) 2013 Amada Co Ltd. All rights reserved.
//

#import "DetailViewController.h"
#import "EditViewController.h"
#import "Person.h"

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController

@synthesize detailItem = _detailItem;
@synthesize nameLabel = _nameLabel;
@synthesize organizationLabel = _organizationLabel;
@synthesize phoneNumberLabel = _phoneNumberLabel;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.
    if (self.detailItem && [self.detailItem isKindOfClass:[Person class]]){
        NSString *name = [NSString stringWithFormat:@"%@ %@",[self.detailItem firstName],
                                                            [self.detailItem lastName]];
        self.nameLabel.text = name;
        self.organizationLabel.text = [self.detailItem organization];
        self.phoneNumberLabel.text = [self.detailItem phoneNumber];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"editDetail"]) {
    NSArray *navigationControllers = [[segue destinationViewController] viewControllers];
    EditViewController *editViewController = [navigationControllers objectAtIndex:0];
    [editViewController setDetailItem:self.detailItem]; }
}

- (IBAction)save:(UIStoryboardSegue *)segue {
    if ([[segue identifier] isEqualToString:@"saveInput"]) {
        EditViewController *editController = [segue sourceViewController];
        [self.detailItem setFirstName:editController.firstNameField.text];
        [self.detailItem setLastName:editController.lastNameField.text];
        [self.detailItem setPhoneNumber:editController.phoneNumberField.text];
        [self.detailItem setOrganization:editController.organizationField.text];
        [self configureView];
    } }
- (IBAction)cancel:(UIStoryboardSegue *)segue {
    if ([[segue identifier] isEqualToString:@"cancelInput"]) {
        // Custom cancel handling can go here.
    } }

@end
