//
//  UNDatabaseTools.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/1.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

@interface UNDatabaseTools : NSObject

+ (instancetype)sharedFMDBTools;

- (BOOL)insertDataWithAPIName:(NSString *)apiName dictData:(NSDictionary *)response;
//- (BOOL)insertDataWithAPIName:(NSString *)apiName jsonData:(NSString *)jsonString;

- (BOOL)deleteTableWithAPIName:(NSString *)apiName;

- (NSDictionary *)getResponseWithAPIName:(NSString *)apiName;

//插入一条数据
- (BOOL)insertDataWithAPIName:(NSString *)apiName stringData:(NSString *)string;
//将数据逐条取出
- (NSArray *)getArrayResponseWithAPIName:(NSString *)apiName;



//插入黑名单数据
- (BOOL)insertBlackListWithPhoneString:(NSString *)string;
//插入多个黑名单列表数据
- (void)insertBlackListWithPhoneLists:(NSArray *)lists;
//删除黑名单数据
- (BOOL)deleteBlackListWithPhoneString:(NSString *)string;
//清空黑名单数据
- (BOOL)deleteAllBlackLists;
//获取黑名单数据
- (NSArray *)getBlackLists;

@end
