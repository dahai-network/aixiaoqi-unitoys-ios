//
//  AddressBookManager.h
//  unitoys
//
//  Created by 董杰 on 2016/12/19.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AddressBookManager : NSObject
+(AddressBookManager *)shareManager;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, strong) NSArray *rowArr;
@property (nonatomic, strong) NSArray *sectionArr;
@property (nonatomic, strong) NSArray *contactsDataArr;
@property (nonatomic, assign) BOOL isOpenedAddress;

@end
