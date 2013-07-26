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
#import "unqlite.h"
#import "Jx9Macros.h"

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
//-(int) editPersonInDb:(Person *)person inDbAtPath:(NSString*)dbPath;
@end

@implementation DetailViewController

@synthesize detailItem = _detailItem;
@synthesize nameLabel = _nameLabel;
@synthesize organizationLabel = _organizationLabel;
@synthesize phoneNumberLabel = _phoneNumberLabel;
@synthesize dbPath = _dbPath;

//-(int) editPersonInDb:(Person *)person inDbAtPath:(NSString*)dbPath
//{
//    if(person == nil || dbPath==nil){
//        return -1;
//    }
//	unqlite_value *pScalar,*pObject; /* Foreign Jx9 variable to be installed later */
//	unqlite *pDb;       /* Database handle */
//	unqlite_vm *pVm;    /* UnQLite VM resulting from successful compilation of the target Jx9 script */
//	int rc;
//    
//	/* Open our database */
//	rc = unqlite_open(&pDb,[dbPath cStringUsingEncoding:NSASCIIStringEncoding],UNQLITE_OPEN_CREATE);
//	if( rc != UNQLITE_OK ){
//		Fatal(0,"Out of memory");
//	}
//	
//	/* Compile our Jx9 script defined above */
//	rc = unqlite_compile(pDb,JX9_PROG_DROPPERSON,sizeof(JX9_PROG_DROPPERSON)-1,&pVm);
//	if( rc != UNQLITE_OK ){
//		/* Compile error, extract the compiler error log */
//		const char *zBuf;
//		int iLen;
//		/* Extract error log */
//		unqlite_config(pDb,UNQLITE_CONFIG_JX9_ERR_LOG,&zBuf,&iLen);
//		if( iLen > 0 ){
//			puts(zBuf);
//		}
//		Fatal(0,"Jx9 compile error");
//	}
//    
//	/* Install a VM output consumer callback */
//	rc = unqlite_vm_config(pVm,UNQLITE_VM_CONFIG_OUTPUT,VmOutputConsumer,0);
//	if( rc != UNQLITE_OK ){
//		Fatal(pDb,0);
//	}
//	
//	/*
//	 * Create a simple scalar variable.
//	 */
//	pScalar = unqlite_vm_new_scalar(pVm);
//	if( pScalar == 0 ){
//		Fatal(0,"Cannot create foreign variable $my_app");
//	}
//    
//	pObject = unqlite_vm_new_array(pVm); /* Unified interface for JSON Objects and Arrays */
//	/* Populate the object with the fields defined above.
//     */
//	unqlite_value_reset_string_cursor(pScalar);
//	
//	/* Add the "firstName" */
//	unqlite_value_string(pScalar,[person.firstName cStringUsingEncoding:NSASCIIStringEncoding],-1);
//	unqlite_array_add_strkey_elem(pObject,"firstName",pScalar); /* Will make it's own copy of pScalar */
//    
//    unqlite_value_reset_string_cursor(pScalar);
//    
//    /* Add the "lastName" */
//	unqlite_value_string(pScalar,[person.lastName cStringUsingEncoding:NSASCIIStringEncoding],-1);
//	unqlite_array_add_strkey_elem(pObject,"lastName",pScalar); /* Will make it's own copy of pScalar */
//    
//    unqlite_value_reset_string_cursor(pScalar);
//    
//    /* Add the "phone" */
//	unqlite_value_string(pScalar,[person.phoneNumber cStringUsingEncoding:NSASCIIStringEncoding],-1);
//	unqlite_array_add_strkey_elem(pObject,"phone",pScalar); /* Will make it's own copy of pScalar */
//    
//    unqlite_value_reset_string_cursor(pScalar);
//    
//    /* Add the "organization" */
//	unqlite_value_string(pScalar,[person.organization cStringUsingEncoding:NSASCIIStringEncoding],-1);
//	unqlite_array_add_strkey_elem(pObject,"organization",pScalar); /* Will make it's own copy of pScalar */
//    
//    unqlite_value_reset_string_cursor(pScalar);
//    
//    unqlite_value_int64(pScalar, person.personId);
//    unqlite_array_add_strkey_elem(pObject, "id", pScalar);
//	
//	/* Now, install the variable and associate the JSON object with it */
//	rc = unqlite_vm_config(
//                           pVm,
//                           UNQLITE_VM_CONFIG_CREATE_VAR, /* Create variable command */
//                           "drop_person", /* Variable name (without the dollar sign) */
//                           pObject    /*value */
//                           );
//	if( rc != UNQLITE_OK ){
//		Fatal(0,"Error while installing $new_person");
//	}
//    
//	/* Release the two values */
//	unqlite_vm_release_value(pVm,pScalar);
//	unqlite_vm_release_value(pVm,pObject);
//    
//	/* Execute our script */
//	unqlite_vm_exec(pVm);
//    
//	/* Release our VM */
//	unqlite_vm_release(pVm);
//	
//	/* Auto-commit the transaction and close our database */
//	unqlite_close(pDb);
//	return 0;
//}


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
