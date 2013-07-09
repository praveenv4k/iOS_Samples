//
//  MasterViewController.m
//  MasterDetailSample
//
//  Created by PraveenKumar Vasudevan on 6/28/13.
//  Copyright (c) 2013 Amada Co Ltd. All rights reserved.
//

#import "MasterViewController.h"

#import "AddViewController.h"
#import "DetailViewController.h"
#import "Person.h"

@interface MasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation MasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)insertNewPerson:(id)sender {
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    Person* friend = [[Person alloc]init];
    friend.firstName = @"<First Name>";
    friend.lastName = @"<Last Name>";
    friend.organization = @"<Organization>";
    friend.phoneNumber = @"<Phone Number>";
    [_objects insertObject:friend atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    Person* friend =_objects[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@",friend.firstName,friend.lastName];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSDate *object = _objects[indexPath.row];
        self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Person *person = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:person];
    }else if([[segue identifier] isEqualToString:@"addDetail"]){
        NSLog(@"Add Detail Segue");
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    UITableView* view = (UITableView*)self.view;
    [view reloadData];
}

- (void)insertNewPerson:(NSString*)firstName withLastName:(NSString*)lastName worksAt:(NSString*)organization contact:(NSString*)phoneNumber {
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    Person* friend = [[Person alloc]init];
    friend.firstName = firstName;
    friend.lastName = lastName;
    friend.organization = organization;
    friend.phoneNumber = phoneNumber;
    [_objects insertObject:friend atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)save:(UIStoryboardSegue *)segue {
    if ([[segue identifier] isEqualToString:@"saveAddedItem"]) {
        AddViewController *addController = [segue sourceViewController];
        NSString* firstName = addController.firstNameField.text;
        NSString* lastName = addController.lastNameField.text;
        if([firstName length] != 0 &&
           [lastName length] != 0){
            NSString* organization = addController.organizationField.text;
            NSString* phoneNumber = addController.phoneNumberField.text;
            [self insertNewPerson:firstName
                 withLastName:lastName worksAt:organization contact:phoneNumber];
        }
        NSLog(@"Save Added Item");
    }
}

- (IBAction)cancel:(UIStoryboardSegue *)segue {
    if ([[segue identifier] isEqualToString:@"cancelAddedItem"]) {
        NSLog(@"Cancel Added Item");
    } }

@end
