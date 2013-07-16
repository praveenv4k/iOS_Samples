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


#define JX9_PROG_ADDPERSON_FETCHDB \
" $zCol = 'persons'; /* Target collection name */"\
" /* Check if the collection 'persons' exists */"\
" if( db_exists($zCol) ){"\
"    print \"Collection persons already created\n\";"\
" }else{"\
"    /* Try to create it */"\
"    $rc = db_create($zCol);"\
"    if ( !$rc ){"\
"        return;"\
"    }"\
"    print \"Collection persons successfully created\n\";"\
"    $zSchema =  {"\
"       firstName : 'string',"\
"       lastName  : 'string',"\
"       phone : 'string',"\
"       organization : 'string'"\
"    };"\
"    db_set_schema($zCol,$zSchema);"\
" }"\
" /*JSON object foreign variable named $new_person*/"\
" print \"\n\\$new_person = \",$new_person..JX9_EOL;"\
" $rc = db_store($zCol,$new_person);"\
" if( !$rc ){"\
"    print db_errlog();"\
"    return;"\
" }"\
" $recCount = db_total_records($zCol);"\
" print \"\nTotal Records in Persons Db:\n\";"\
" print $recCount..JX9_EOL;"\
" $zCallback = function($rec){"\
"     return TRUE;"\
" };"\
" $lastId = db_last_record_id($zCol);"\
" $dbRecords = db_fetch_by_id($zCol,$lastId);"\
" print $dbRecords;"

#define JX9_PROG_FETCHPERSONDB \
" $zCol = 'persons'; /* Target collection name */"\
" /* Check if the collection 'persons' exists */"\
" if( db_exists($zCol) ){"\
" }else{"\
"        return;"\
" }"\
" $zCallback = function($rec){"\
"     return TRUE;"\
" };"\
" $dbRecords = db_fetch_all($zCol,$zCallback);"\
" print $dbRecords;"\
" foreach ($dbRecords as $value)"\
" fillObjects($value);"

//" dump(fillObjects($value));"


#define JX9_PROG_UPDATEPERSONDB \
" $zCol = 'persons'; /* Target collection name */"\
" /* Check if the collection 'persons' exists */"\
" if( db_exists($zCol) ){"\
" }else{"\
"        return;"\
" }"\
" /*JSON object foreign variable named $edit_person*/"\
" print \"\n\\$edit_person = \",$edit_person..JX9_EOL;"\
" $rc = db_store($zCol,$edit_person);"\
" if( !$rc ){"\
"    print db_errlog();"\
"    return;"\
" }"\
" $recCount = db_total_records($zCol);"\
" print \"\nTotal Records in Persons Db:\n\";"\
" print $recCount..JX9_EOL;"\
" $zCallback = function($rec){"\
"     return TRUE;"\
" };"\
" $dbRecords = db_fetch_all($zCol,$zCallback);"\
" print $dbRecords;"


/* Forward declaration: VM output consumer callback */
static int VmOutputConsumer(const void *pOutput,unsigned int nOutLen,void *pUserData /* Unused */);


@interface MasterViewController () {
    NSMutableArray *_objects;
    NSString* _dbPath;
}

- (void) createDatabase:(NSString*)path;
-(int) insertPersonIntoDb:(Person *)person intoDbAtPath:(NSString*)dbPath;
-(int) fetchAllPersonsFromDb:(NSString*)dbPath;
static Person* personFromDbObject(unqlite_value* dbObject);
@end

@implementation MasterViewController


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

static int JsonArrayWalker(unqlite_value *pKey,unqlite_value *pData,void *pUserData)
{
	unqlite_value* value1 = unqlite_array_fetch(pData, "firstName", -1);
    if(value1!= 0){
        unqlite_value* value2 = unqlite_array_fetch(pData, "lastName", -1);
        if(value2!=0){
            unqlite_value* value3 = unqlite_array_fetch(pData, "phone", -1);
            if(value3!=0){
                unqlite_value* value4 = unqlite_array_fetch(pData, "organization", -1);
                if(value4!=0){
                    unqlite_value* value5 = unqlite_array_fetch(pData, "__id", -1);
                    if(value5!=0){
                        const char *zData1 = unqlite_value_to_string(value1,0);
                        const char *zData2 = unqlite_value_to_string(value2,0);
                        const char *zData3 = unqlite_value_to_string(value3,0);
                        const char *zData4 = unqlite_value_to_string(value4,0);
                        int personId  = unqlite_value_to_int64(value5);
                        
                        Person* person = [[Person alloc]init];
                        person.firstName = [NSString stringWithUTF8String:zData1];
                        person.lastName = [NSString stringWithUTF8String:zData2];
                        person.phoneNumber = [NSString stringWithUTF8String:zData3];
                        person.organization = [NSString stringWithUTF8String:zData4];
                        person.personId = personId;
                        
                        NSMutableArray* objects = (__bridge NSMutableArray*)pUserData;
                        if(objects!=NULL){
                            [objects insertObject:person atIndex:0];
                        }
                        
                        printf("%s %s;%s,%s,%d\n",zData1,zData2,zData3,zData4,personId);
                    }
                }
            }
        }
    }
	return UNQLITE_OK;
}

static int JsonPersonArrayWalker(unqlite_value *pKey,unqlite_value *pData,void *pUserData /* Unused */)
{
    unqlite_value* value1 = unqlite_array_fetch(pData, "firstName", -1);
    if(value1!= 0){
        unqlite_value* value2 = unqlite_array_fetch(pData, "lastName", -1);
        if(value2!=0){
            unqlite_value* value3 = unqlite_array_fetch(pData, "phone", -1);
            if(value3!=0){
                unqlite_value* value4 = unqlite_array_fetch(pData, "organization", -1);
                if(value4!=0){
                    unqlite_value* value5 = unqlite_array_fetch(pData, "__id", -1);
                    if(value5!=0){
                        const char *zData1 = unqlite_value_to_string(value1,0);
                        const char *zData2 = unqlite_value_to_string(value2,0);
                        const char *zData3 = unqlite_value_to_string(value3,0);
                        const char *zData4 = unqlite_value_to_string(value4,0);
                        int personId  = unqlite_value_to_int64(value5);
                        
                        //printf("%s %s;%s,%s,%d\n",zData1,zData2,zData3,zData4,personId);
                    }
                }
            }
        }
    }
	return UNQLITE_OK;
}

-(int) insertPersonIntoDb:(Person *)person intoDbAtPath:(NSString*)dbPath
{
    if(person == nil || dbPath==nil){
        return -1;
    }
	unqlite_value *pScalar,*pObject; /* Foreign Jx9 variable to be installed later */
	unqlite *pDb;       /* Database handle */
	unqlite_vm *pVm;    /* UnQLite VM resulting from successful compilation of the target Jx9 script */
	int rc;
    
	/* Open our database */
	rc = unqlite_open(&pDb,[dbPath cStringUsingEncoding:NSASCIIStringEncoding],UNQLITE_OPEN_CREATE);
	if( rc != UNQLITE_OK ){
		Fatal(0,"Out of memory");
	}
	
	/* Compile our Jx9 script defined above */
	rc = unqlite_compile(pDb,JX9_PROG_ADDPERSON_FETCHDB,sizeof(JX9_PROG_ADDPERSON_FETCHDB)-1,&pVm);
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
	
	/* Add the "firstName" */
	unqlite_value_string(pScalar,[person.firstName cStringUsingEncoding:NSASCIIStringEncoding],-1);
	unqlite_array_add_strkey_elem(pObject,"firstName",pScalar); /* Will make it's own copy of pScalar */
    
    unqlite_value_reset_string_cursor(pScalar);
    
    /* Add the "lastName" */
	unqlite_value_string(pScalar,[person.lastName cStringUsingEncoding:NSASCIIStringEncoding],-1);
	unqlite_array_add_strkey_elem(pObject,"lastName",pScalar); /* Will make it's own copy of pScalar */
    
    unqlite_value_reset_string_cursor(pScalar);
    
    /* Add the "phone" */
	unqlite_value_string(pScalar,[person.phoneNumber cStringUsingEncoding:NSASCIIStringEncoding],-1);
	unqlite_array_add_strkey_elem(pObject,"phone",pScalar); /* Will make it's own copy of pScalar */
    
    unqlite_value_reset_string_cursor(pScalar);
    
    /* Add the "organization" */
	unqlite_value_string(pScalar,[person.organization cStringUsingEncoding:NSASCIIStringEncoding],-1);
	unqlite_array_add_strkey_elem(pObject,"organization",pScalar); /* Will make it's own copy of pScalar */
	
	/* Now, install the variable and associate the JSON object with it */
	rc = unqlite_vm_config(
                           pVm,
                           UNQLITE_VM_CONFIG_CREATE_VAR, /* Create variable command */
                           "new_person", /* Variable name (without the dollar sign) */
                           pObject    /*value */
                           );
	if( rc != UNQLITE_OK ){
		Fatal(0,"Error while installing $new_person");
	}
    
	/* Release the two values */
	unqlite_vm_release_value(pVm,pScalar);
	unqlite_vm_release_value(pVm,pObject);
    
	/* Execute our script */
	unqlite_vm_exec(pVm);
	
	/* Extract the content of the variable named $my_config defined in the
	 * running script which hold a simple JSON object.
	 */
	pObject = unqlite_vm_extract_variable(pVm,"dbRecords");
	if( pObject && unqlite_value_is_json_object(pObject) ){
        Person* addPerson = personFromDbObject(pObject);
        if(addPerson!=nil){
            if(_objects!= nil){
                [_objects insertObject:addPerson atIndex:0];
            }
        }
	}
    else if(pObject && unqlite_value_is_json_array(pObject)){
        /* Iterate over object fields */
		printf("\n\nTotal fields in $dbRecords = %u\n",unqlite_array_count(pObject));
        unqlite_array_walk(pObject, JsonArrayWalker, (__bridge void*)_objects);
    }
    
	/* Release our VM */
	unqlite_vm_release(pVm);
	
	/* Auto-commit the transaction and close our database */
	unqlite_close(pDb);
	return 0;
}

static Person* personFromDbObject(unqlite_value* pObject){
    if( pObject && unqlite_value_is_json_object(pObject) ){
        unqlite_value* value = unqlite_array_fetch(pObject, "firstName", -1);
        if(value != NULL){
            NSString* firstName = [NSString stringWithUTF8String:unqlite_value_to_string(value, 0)];
            value = unqlite_array_fetch(pObject, "lastName", -1);
            if(value != NULL){
                NSString* lastName = [NSString stringWithUTF8String:unqlite_value_to_string(value, 0)];
                value = unqlite_array_fetch(pObject, "phone", -1);
                if(value != NULL){
                    NSString* phone = [NSString stringWithUTF8String:unqlite_value_to_string(value, 0)];
                    value = unqlite_array_fetch(pObject, "organization", -1);
                    if(value != NULL){
                        NSString* organization = [NSString stringWithUTF8String:unqlite_value_to_string(value, 0)];
                        value = unqlite_array_fetch(pObject, "__id", -1);
                        if(value != NULL){
                            int personId = unqlite_value_to_int64(value);
                            Person* addPerson = [[Person alloc]init];
                            addPerson.firstName = firstName;
                            addPerson.lastName = lastName;
                            addPerson.phoneNumber = phone;
                            addPerson.organization = organization;
                            addPerson.personId = personId;
                            return addPerson;
                            }
                        }
                }
            }
        }
    }
    return nil;
}

int fillObjects(unqlite_context *pCtx, int argc, unqlite_value **argv)
{
    //printf("Number of Arguments : %d",argc);
    if (argc>0) {
        unqlite_value* value = argv[0];
        if(value!=0){
            Person* person = personFromDbObject(value);
            if(person!=nil){
                NSLog(@"%@ %@",person.firstName,person.lastName);
            }
        }
    }
    return UNQLITE_OK;
}

-(int) fetchAllPersonsFromDb:(NSString*)dbPath
{
    if(dbPath==nil){
        return -1;
    }
	unqlite_value *pObject; /* Foreign Jx9 variable to be installed later */
	unqlite *pDb;       /* Database handle */
	unqlite_vm *pVm;    /* UnQLite VM resulting from successful compilation of the target Jx9 script */
	int rc;
    
	/* Open our database */
	rc = unqlite_open(&pDb,[dbPath cStringUsingEncoding:NSASCIIStringEncoding],UNQLITE_OPEN_CREATE);
	if( rc != UNQLITE_OK ){
		Fatal(0,"Out of memory");
	}
	
	/* Compile our Jx9 script defined above */
	rc = unqlite_compile(pDb,JX9_PROG_FETCHPERSONDB,sizeof(JX9_PROG_FETCHPERSONDB)-1,&pVm);
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
    
	/* Install a VM output consumer callback */
	rc = unqlite_vm_config(pVm,UNQLITE_VM_CONFIG_OUTPUT,VmOutputConsumer,0);
	if( rc != UNQLITE_OK ){
		Fatal(pDb,0);
	}
    
    rc = unqlite_create_function(pVm
                                 , "fillObjects", fillObjects, 0);
	if( rc != UNQLITE_OK ){
		Fatal(pDb,0);
	}
    
	/* Execute our script */
	unqlite_vm_exec(pVm);
	
	/* Extract the content of the variable named $my_config defined in the
	 * running script which hold a simple JSON object.
	 */
	pObject = unqlite_vm_extract_variable(pVm,"dbRecords");
	if( pObject && unqlite_value_is_json_object(pObject) ){
		/* Iterate over object fields */
		printf("\n\nTotal fields in $dbRecords = %u\n",unqlite_array_count(pObject));
        unqlite_array_walk(pObject,JsonObjectWalker,0);
	}
    else if(pObject && unqlite_value_is_json_array(pObject)){
        /* Iterate over object fields */
        [_objects removeAllObjects];
		printf("\n\nTotal fields in $dbRecords = %u\n",unqlite_array_count(pObject));
        unqlite_array_walk(pObject, JsonPersonArrayWalker,0);
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
        [self fetchAllPersonsFromDb:_dbPath];
        //testJx9();
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
    
    //[_objects insertObject:friend atIndex:0];
    
    [self insertPersonIntoDb:friend intoDbAtPath:_dbPath];
    
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
