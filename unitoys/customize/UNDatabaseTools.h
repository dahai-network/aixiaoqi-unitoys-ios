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

- (void)logoutClearDatabase;

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

//删除短信数据库(清空所有短信)
- (BOOL)deleteMessageDatabase;

//获取短信列表最后一条的时间
- (NSString *)getLastTimeWithMessageList;
//获取短信列表指定数据
- (NSDictionary *)getMessageListDataWithPhone:(NSString *)phone;
//获取指定页数的短信列表
- (NSArray *)getMessageListsWithPage:(NSInteger)page;
//插入短信列表
- (BOOL)insertMessageListWithMessageLists:(NSArray *)messageList;
//删除短信列表(需要同时删除所有短信)
- (BOOL)deteleMessageListWithPhoneLists:(NSArray *)phoneLists;

//获取联系人短信内容最后一条的时间
- (NSString *)getLastTimeMessageContentWithPhone:(NSString *)phone;
//获取联系人短信内容最后一条的数据
- (NSDictionary *)getLastDataMessageContentWithPhone:(NSString *)phone;
//获取指定页数的短信内容
- (NSArray *)getMessageContentWithPage:(NSInteger)page Phone:(NSString *)phone;
//插入短信内容
- (BOOL)insertMessageContentWithMessageContent:(NSArray *)messageContents Phone:(NSString *)phone;
//删除指定短信内容(根据短信ID删除,如果短信已删除完成,需要删除短信列表)
- (BOOL)deteleMessageContentWithSMSIDLists:(NSArray *)smsIDLists WithPhone:(NSString *)phone;

//更新指定短信状态
- (BOOL)updateMessageStatuWithSMSIDDictArray:(NSArray<NSDictionary *> *)smsIds;

@end
