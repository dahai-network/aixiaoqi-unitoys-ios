//
//  UNBLEDataManager.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/7.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNBLEDataManager.h"

@interface UNBLEDataManager()

@property (nonatomic, copy) NSString *shortString;
@property (nonatomic, copy) NSString *longString;

@end

@implementation UNBLEDataManager

+ (UNBLEDataManager *)sharedInstance
{
    static UNBLEDataManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nil] init];
    });
    return instance;
}

//type  1 short 2 long
- (void)receiveDataFromBLE:(NSString *)bleString WithType:(NSInteger)type
{
    if (type == 1) {
        self.shortString = bleString;
    }else if (type == 2){
        self.longString = bleString;
    }
}

- (void)clearData
{
    self.shortString = nil;
    self.longString = nil;
}

@end
