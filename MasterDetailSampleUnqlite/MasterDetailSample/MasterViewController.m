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
#import "unqlite.h"

@interface MasterViewController () {
    NSMutableArray *_objects;
    NSString* _dbPath;
}

- (void) createDatabase:(NSString*)path;

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
    
//    NSFileManager* sharedFM = [NSFileManager defaultManager];
//    NSArray* paths = [sharedFM URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if([paths count] > 0){
        NSString* docs_dir = [paths objectAtIndex:0];
        _dbPath = [docs_dir stringByAppendingPathComponent:@"Person.db"];
        NSLog(@"%@",_dbPath);
        NSFileManager* sharedFM = [NSFileManager defaultManager];
        if([sharedFM fileExistsAtPath:_dbPath]){
            NSLog(@"%@",@"Person db Exists");
            
        }
        else{
            [self createDatabase:_dbPath];
        }
    }
}

-(void)createDatabase:(NSString *)path{
    if(path != nil){
        int rc;
        unqlite* pDb;
        
        rc = unqlite_open(&pDb, [path cStringUsingEncoding:NSASCIIStringEncoding],UNQLITE_OPEN_CREATE);
        
        if(rc != UNQLITE_OK){
            NSLog(@"%@",@"Error Creating/Opening Person Database");
        }
//        unqlite_close(pDb);
        
        // Store some records
        rc = unqlite_kv_store(pDb,"test",-1,"Hello World",11); //test => 'Hello World'
        if( rc != UNQLITE_OK ){
            //Insertion fail, Hande error (See below)
            return;
        }
        // A small formatted string
        rc = unqlite_kv_store_fmt(pDb,"date",-1,"Current date: %d:%d:%d",2013,06,07);
        if( rc != UNQLITE_OK ){
            //Insertion fail, Hande error (See below)
            return;
        }
        
        //Switch to the append interface
        rc = unqlite_kv_append(pDb,"msg",-1,"Hello, ",7); //msg => 'Hello, '
        if( rc == UNQLITE_OK ){
            //The second chunk
            rc = unqlite_kv_append(pDb,"msg",-1,"Current time is: ",17); //msg => 'Hello, Current time is: '
            if( rc == UNQLITE_OK ){
                //The last formatted chunk
                rc = unqlite_kv_append_fmt(pDb,"msg",-1,"%d:%d:%d",10,16,53); //msg => 'Hello, Current time is: 10:16:53'
            }
        }
        
        //Delete a record
        unqlite_kv_delete(pDb,"test",-1);
        
        //Store 20 random records.
        for(int i = 0 ; i < 20 ; ++i ){
            char zKey[12]; //Random generated key
            char zData[34]; //Dummy data
            
            // generate the random key
            unqlite_util_random_string(pDb,zKey,sizeof(zKey));
            
            // Perform the insertion
            rc = unqlite_kv_store(pDb,zKey,sizeof(zKey),zData,sizeof(zData));
            if( rc != UNQLITE_OK ){
                break;
            }
        }
        
        if( rc != UNQLITE_OK ){
            //Insertion fail, Handle error
            const char *zBuf;
            int iLen;
            /* Something goes wrong, extract the database error log */
            unqlite_config(pDb,UNQLITE_CONFIG_ERR_LOG,&zBuf,&iLen);
            if( iLen > 0 ){
                puts(zBuf);
            }
            if( rc != UNQLITE_BUSY && rc != UNQLITE_NOTIMPLEMENTED ){
                /* Rollback */
                unqlite_rollback(pDb);
            }
        }
        
        //Auto-commit the transaction and close our handle.
        unqlite_close(pDb);

    }
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
