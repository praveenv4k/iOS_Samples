//
//  Person.h
//  MasterDetailSample
//
//  Created by PraveenKumar Vasudevan on 6/28/13.
//  Copyright (c) 2013 Amada Co Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject

@property (nonatomic) int personId;
@property (copy,nonatomic) NSString* firstName;
@property (copy,nonatomic) NSString* lastName;
@property (copy,nonatomic) NSString* organization;
@property (copy,nonatomic) NSString* phoneNumber;

@end
