//
//  BlueToothDataManager.m
//  unitoys
//
//  Created by 董杰 on 2016/11/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BlueToothDataManager.h"
static BlueToothDataManager * manager=nil;

@implementation BlueToothDataManager

+ (BlueToothDataManager *)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

@end
