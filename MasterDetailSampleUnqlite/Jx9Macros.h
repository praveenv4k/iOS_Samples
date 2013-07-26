//
//  Jx9Macros.h
//  MasterDetailSample
//
//  Created by PraveenKumar Vasudevan on 7/23/13.
//  Copyright (c) 2013 Amada Co Ltd. All rights reserved.
//

#ifndef MasterDetailSample_Jx9Macros_h
#define MasterDetailSample_Jx9Macros_h

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
" print $dbRecords;"

//" foreach ($dbRecords as $value)"\
//" fillObjects($value);"

//" dump(fillObjects($value));"


#define JX9_PROG_UPDATEPERSONDB \
" $zCol = 'persons'; /* Target collection name */"\
" /* Check if the collection 'persons' exists */"\
" if( db_exists($zCol) ){"\
" }else{"\
"        return;"\
" }"\
" /*JSON object foreign variable named $edit_person*/"\
" $dbRecord = db_fetch_by_id($zCol,$edit_person.id);"\
" if( $dbRecord == NULL ){"\
"        return;"\
" }"\
" print $dbRecord;"\
" $dbRecord.firstName = $edit_person.firstName"\
" $dbRecord.firstName = $edit_person.lastName"\
" $dbRecord.firstName = $edit_person.phone"\
" $dbRecord.firstName = $edit_person.organization"\
" $rc = db_store($zCol,$dbRecord);"\
" if( !$rc ){"\
"    print db_errlog();"\
"    return;"\
" }"\
" $recCount = db_total_records($zCol);"\
" print \"\nTotal Records in Persons Db:\n\";"\
" print $recCount..JX9_EOL;"

#define JX9_PROG_DROPPERSON \
" $zCol = 'persons'; /* Target collection name */"\
" /* Check if the collection 'persons' exists */"\
" if( db_exists($zCol) ){"\
" }else{"\
"        return;"\
" }"\
" /*JSON object foreign variable named $edit_person*/"\
" print \"\n\\$drop_person = \",$drop_person..JX9_EOL;"\
" $rc = db_drop_record($zCol,$drop_person.id);"\
" if( !$rc ){"\
"    print db_errlog();"\
"    return;"\
" }"\
" $recCount = db_total_records($zCol);"\
" print \"\nTotal Records in Persons Db:\n\";"\
" print $recCount..JX9_EOL;"

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

#endif
