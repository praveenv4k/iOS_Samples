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

/*
 * Banner.
 */
static const char zBanner[] = {
	"============================================================\n"
	"UnQLite Document-Store (Via Jx9) Data Share Intro           \n"
	"                                         http://unqlite.org/\n"
	"============================================================\n"
};
/*
 * Extract the database error log and exit.
 */
static void Fatal(unqlite *pDb,const char *zMsg)
{
	if( pDb ){
		const char *zErr;
		int iLen = 0; /* Stupid cc warning */
        
		/* Extract the database error log */
		unqlite_config(pDb,UNQLITE_CONFIG_ERR_LOG,&zErr,&iLen);
		if( iLen > 0 ){
			/* Output the DB error log */
			puts(zErr); /* Always null termniated */
		}
	}else{
		if( zMsg ){
            NSLog(@"%@",[NSString stringWithUTF8String:zMsg]);
		}
	}
	/* Manually shutdown the library */
	unqlite_lib_shutdown();
	/* Exit immediately */
	exit(0);
}
/*
 * The following walker callback is made available to the [unqlite_array_walk()] interface
 * which is used to iterate over the JSON object extracted from the running script.
 * (See below for more information).
 */
static int JsonObjectWalker(unqlite_value *pKey,unqlite_value *pData,void *pUserData /* Unused */)
{
	const char *zKey,*zData;
	/* Extract the key and the data field */
	zKey = unqlite_value_to_string(pKey,0);
	zData = unqlite_value_to_string(pData,0);
	/* Dump */
	NSLog(@"%@ ===> %@",
           [NSString stringWithUTF8String:zKey],
           [NSString stringWithUTF8String:zData]
           );
	return UNQLITE_OK;
}

static int JsonArrayWalker(unqlite_value *pKey,unqlite_value *pData,void *pUserData /* Unused */)
{
	const char *zData;
    unqlite_value* value1 = unqlite_array_fetch(pData, "unqlite_signature", -1);
    if(value1!= 0){
    unqlite_value* value2 = unqlite_array_fetch(pData, "time", -1);
        if(value2!=0){
            unqlite_value* value3 = unqlite_array_fetch(pData, "date", -1);
            if(value3!=0){
                	zData = unqlite_value_to_string(value1,0);
                	/* Dump */
                	NSLog(@"Signature ===> %@",
                          
                          [NSString stringWithUTF8String:zData]
                          );
                zData = unqlite_value_to_string(value2,0);
                /* Dump */
                NSLog(@"Time ===> %@",
                      
                      [NSString stringWithUTF8String:zData]
                      );
                zData = unqlite_value_to_string(value3,0);
                /* Dump */
                NSLog(@"Date ===> %@",
                      
                      [NSString stringWithUTF8String:zData]
                      );

            }
        }
    }
//	/* Extract the key and the data field */
//	zKey = unqlite_value_to_string(pKey,0);
//	zData = unqlite_value_to_string(pData,0);
//	/* Dump */
//	NSLog(@"%@ ===> %@",
//          [NSString stringWithUTF8String:zKey],
//          [NSString stringWithUTF8String:zData]
//          );
	return UNQLITE_OK;
}

/* Forward declaration: VM output consumer callback */
static int VmOutputConsumer(const void *pOutput,unsigned int nOutLen,void *pUserData /* Unused */);
/*
 * The following is the Jx9 Program to be executed later by the UnQLite VM:
 *
 * This program demonstrate how data is shared between the host application
 * and the running JX9 script. The main() function defined below creates and install
 * two foreign variables named respectively $my_app and $my_data. The first is a simple
 * scalar value while the last is a complex JSON object. these foreign variables are
 * made available to the running script using the [unqlite_vm_config()] interface with
 * a configuration verb set to UNQLITE_VM_CONFIG_CREATE_VAR.
 *
 * Jx9 Program:
 *
 * print "Showing foreign variables contents\n";
 * //Scalar foreign variable named $my_app
 * print "\$my_app =",$my_app..JX9_EOL;
 * //Foreign JSON object named $my_data
 * print "\$my_data = ",$my_data;
 * //Dump command line arguments
 * if( count($argv) > 0 ){
 *  print "\nCommand line arguments:\n";
 *  print $argv;
 * }else{
 *  print "\nEmpty command line";
 * }
 * //Return a simple JSON object to the host application
 * $my_config = {
 *        "unqlite_signature" : db_sig(), //UnQLite Unique signature
 *        "time" : __TIME__, //Current time
 *        "date" : __DATE__  //Current date
 * };
 */
#define JX9_PROG \
"print \"Showing foreign variables contents\n\n\";"\
" /*Scalar foreign variable named $my_app*/"\
" print \"\\$my_app = \",$my_app..JX9_EOL;"\
" /*JSON object foreign variable named $my_data*/"\
" print \"\n\\$my_data = \",$my_data..JX9_EOL;"\
" /*Dump command line arguments*/"\
" if( count($argv) > 0 ){"\
"  print \"\nCommand line arguments:\n\";"\
"  print $argv..JX9_EOL;"\
" }else{"\
"  print \"\nEmpty command line\";"\
" }"\
" /*Return a simple JSON object to the host application*/"\
" $my_config = ["\
" {"\
"        'unqlite_signature' : db_sig(),  /* UnQLite Unique version*/"\
"        'time' : __TIME__, /*Current time*/"\
"        'date' : __DATE__  /*Current date*/"\
" },{"\
"        'unqlite_signature' : db_sig(),  /* UnQLite Unique version*/"\
"        'time' : __TIME__, /*Current time*/"\
"        'date' : __DATE__  /*Current date*/"\
" },{"\
"        'unqlite_signature' : db_sig(),  /* UnQLite Unique version*/"\
"        'time' : __TIME__, /*Current time*/"\
"        'date' : Hello  /*Current date*/"\
" }];"

int testJx9()
{
	unqlite_value *pScalar,*pObject; /* Foreign Jx9 variable to be installed later */
	unqlite *pDb;       /* Database handle */
	unqlite_vm *pVm;    /* UnQLite VM resulting from successful compilation of the target Jx9 script */
	int rc;
    
	puts(zBanner);
    
	/* Open our database */
	rc = unqlite_open(&pDb,":mem:" /* In-mem DB */,UNQLITE_OPEN_CREATE);
	if( rc != UNQLITE_OK ){
		Fatal(0,"Out of memory");
	}
	
	/* Compile our Jx9 script defined above */
	rc = unqlite_compile(pDb,JX9_PROG,sizeof(JX9_PROG)-1,&pVm);
	if( rc != UNQLITE_OK ){
		/* Compile error, extract the compiler error log */
		const char *zBuf;
		int iLen;
		/* Extract error log */
		unqlite_config(pDb,UNQLITE_CONFIG_JX9_ERR_LOG,&zBuf,&iLen);
		if( iLen > 0 ){
			puts(zBuf);
		}
		Fatal(0,"Jx9 compile error");
	}
    
	/* Register script agruments so we can access them later using the $argv[]
	 * array from the compiled Jx9 program.
	 */
//	for( n = 1; n < argc ; ++n ){
//		unqlite_vm_config(pVm, UNQLITE_VM_CONFIG_ARGV_ENTRY, argv[n]/* Argument value */);
//	}
    
	/* Install a VM output consumer callback */
	rc = unqlite_vm_config(pVm,UNQLITE_VM_CONFIG_OUTPUT,VmOutputConsumer,0);
	if( rc != UNQLITE_OK ){
		Fatal(pDb,0);
	}
	
	/*
	 * Create a simple scalar variable.
	 */
	pScalar = unqlite_vm_new_scalar(pVm);
	if( pScalar == 0 ){
		Fatal(0,"Cannot create foreign variable $my_app");
	}
	/* Populate the variable with the desired information */
	unqlite_value_string(pScalar,"My Host Application/1.2.5",-1/*Compule length automatically*/); /* Dummy signature*/
	/*
	 * Install the variable ($my_app).
	 */
	rc = unqlite_vm_config(
                           pVm,
                           UNQLITE_VM_CONFIG_CREATE_VAR, /* Create variable command */
                           "my_app", /* Variable name (without the dollar sign) */
                           pScalar   /* Value */
                           );
	if( rc != UNQLITE_OK ){
		Fatal(0,"Error while installing $my_app");
	}
	/* To access this foreign variable from the running script, simply invoke it
	 * as follows:
	 *  print $my_app;
	 * or
	 *  dump($my_app);
	 */
    
	/*
	 * Now, it's time to create and install a more complex variable which is a JSON
	 * object named $my_data.
	 * The JSON Object looks like this:
	 *  {
	 *     "path" : "/usr/local/etc",
	 *     "port" : 8082,
	 *     "fork" : true
	 *  };
	 */
	pObject = unqlite_vm_new_array(pVm); /* Unified interface for JSON Objects and Arrays */
	/* Populate the object with the fields defined above.
     */
	unqlite_value_reset_string_cursor(pScalar);
	
	/* Add the "path" : "/usr/local/etc" entry */
	unqlite_value_string(pScalar,"/usr/local/etc",-1);
	unqlite_array_add_strkey_elem(pObject,"path",pScalar); /* Will make it's own copy of pScalar */
	
	/* Add the "port" : 8080 entry */
	unqlite_value_int(pScalar,8080);
	unqlite_array_add_strkey_elem(pObject,"port",pScalar); /* Will make it's own copy of pScalar */
	
	/* Add the "fork": true entry */
	unqlite_value_bool(pScalar,1 /* TRUE */);
	unqlite_array_add_strkey_elem(pObject,"fork",pScalar); /* Will make it's own copy of pScalar */
    
	/* Now, install the variable and associate the JSON object with it */
	rc = unqlite_vm_config(
                           pVm,
                           UNQLITE_VM_CONFIG_CREATE_VAR, /* Create variable command */
                           "my_data", /* Variable name (without the dollar sign) */
                           pObject    /*value */
                           );
	if( rc != UNQLITE_OK ){
		Fatal(0,"Error while installing $my_data");
	}
    
	/* Release the two values */
	unqlite_vm_release_value(pVm,pScalar);
	unqlite_vm_release_value(pVm,pObject);
    
	/* Execute our script */
	unqlite_vm_exec(pVm);
	
	/* Extract the content of the variable named $my_config defined in the
	 * running script which hold a simple JSON object.
	 */
	pObject = unqlite_vm_extract_variable(pVm,"my_config");
	if( pObject && unqlite_value_is_json_object(pObject) ){
		/* Iterate over object fields */
		printf("\n\nTotal fields in $my_config = %u\n",unqlite_array_count(pObject));
		unqlite_array_walk(pObject,JsonObjectWalker,0);
	}
    else if(pObject && unqlite_value_is_json_array(pObject)){
        /* Iterate over object fields */
		printf("\n\nTotal fields in $my_config = %u\n",unqlite_array_count(pObject));
        unqlite_array_walk(pObject, JsonArrayWalker, 0);
    }
    
	/* Release our VM */
	unqlite_vm_release(pVm);
	
	/* Auto-commit the transaction and close our database */
	unqlite_close(pDb);
	return 0;
}

#ifdef __WINNT__
#include <Windows.h>
#else
/* Assume UNIX */
#include <unistd.h>
#endif
/*
 * The following define is used by the UNIX build process and have
 * no particular meaning on windows.
 */
#ifndef STDOUT_FILENO
#define STDOUT_FILENO	1
#endif
/*
 * VM output consumer callback.
 * Each time the UnQLite VM generates some outputs, the following
 * function gets called by the underlying virtual machine to consume
 * the generated output.
 *
 * All this function does is redirecting the VM output to STDOUT.
 * This function is registered via a call to [unqlite_vm_config()]
 * with a configuration verb set to: UNQLITE_VM_CONFIG_OUTPUT.
 */
static int VmOutputConsumer(const void *pOutput,unsigned int nOutLen,void *pUserData /* Unused */)
{
#ifdef __WINNT__
	BOOL rc;
	rc = WriteFile(GetStdHandle(STD_OUTPUT_HANDLE),pOutput,(DWORD)nOutLen,0,0);
	if( !rc ){
		/* Abort processing */
		return UNQLITE_ABORT;
	}
#else
	ssize_t nWr;
	nWr = write(STDOUT_FILENO,pOutput,nOutLen);
	if( nWr < 0 ){
		/* Abort processing */
		return UNQLITE_ABORT;
	}
#endif /* __WINT__ */
	
	/* All done, data was redirected to STDOUT */
	return UNQLITE_OK;
}

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
        testJx9();
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
