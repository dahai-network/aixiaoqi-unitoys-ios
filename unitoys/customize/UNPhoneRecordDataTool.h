//
//  UNPhoneRecordDataTool.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UNPhoneRecordDataTool : NSObject

+ (instancetype)sharedPhoneRecordDataTool;

//获取到的数据为多条数组,以来去电分组,需要手动排序
- (NSArray *)getRecordsWithPhoneNumber:(NSString *)phoneNumber;

@end
