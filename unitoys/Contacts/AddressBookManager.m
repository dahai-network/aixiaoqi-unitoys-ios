//
//  AddressBookManager.m
//  unitoys
//
//  Created by 董杰 on 2016/12/19.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "AddressBookManager.h"
static AddressBookManager *manager = nil;

@implementation AddressBookManager

+(AddressBookManager *)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

@end
