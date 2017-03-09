//
//  UNBLEDataManager.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/7.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>


//typedef void(^BLEDataReceiveFinished)(NSString *shortData, NSString *longData);
@interface UNBLEDataManager : NSObject

+ (UNBLEDataManager *)sharedInstance;

@property (nonatomic, readonly) NSString *shortString;
@property (nonatomic, readonly) NSString *longString;

- (void)receiveDataFromBLE:(NSString *)bleString WithType:(NSInteger)type;

- (void)clearData;

@end
