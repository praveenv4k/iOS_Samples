//
//  EditViewController.h
//  MasterDetailSample
//
//  Created by PraveenKumar Vasudevan on 6/30/13.
//  Copyright (c) 2013 Amada Co Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditViewController : UITableViewController<UITextFieldDelegate>

@property (strong,nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *organizationField;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberField;

@end
