//
//  UNDatabaseTools.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/1.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNDatabaseTools.h"

#define MessagePageSize 20

@interface UNDatabaseTools()

@property (nonatomic, copy) NSString *phoneRecordfilePath;
@property (nonatomic, copy) NSString *msgRecordfilePath;
//@property (nonatomic, copy) NSString *msgContentfilePath;
//@property (nonatomic, strong) FMDatabase *database;

@end

static FMDatabaseQueue *_phoneDatabase =nil;
static FMDatabaseQueue *_msgDatabase =nil;
//static FMDatabaseQueue *_msgContentDatabase =nil;
@implementation UNDatabaseTools

- (NSString *)getPhoneStr
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"][@"Tel"];
}

+ (instancetype)sharedFMDBTools
{
    static UNDatabaseTools *databaseTool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        databaseTool = [[UNDatabaseTools alloc] init];
    });
    return databaseTool;
}

- (void)logoutClearDatabase
{
    [self deleteMessageDatabase];
    _phoneDatabase = nil;
    _msgDatabase = nil;
    _phoneRecordfilePath = nil;
    _msgRecordfilePath = nil;
}

- (FMDatabaseQueue *)phoneDatabase
{
    if (!_phoneDatabase) {
        if ([self phoneRecordfilePath]) {
            _phoneDatabase = [FMDatabaseQueue databaseQueueWithPath:[self phoneRecordfilePath]];
        }else{
            _phoneDatabase = nil;
        }
    }
    return _phoneDatabase;
}

- (NSString *)phoneRecordfilePath
{
    if ([self getPhoneStr]) {
        NSString *dataName = [NSString stringWithFormat:@"%@.db", [NSString stringWithFormat:@"%@_dataName", [self getPhoneStr]]];
        NSString *string = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *stringPath = [string stringByAppendingPathComponent:dataName];
        return stringPath;
    }
    return nil;
}

- (BOOL)isHasFileWithPath:(NSString *)dbPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断是否有数据库文件
    if ([fileManager fileExistsAtPath:dbPath]) {
        return YES;
    }else{
        NSLog(@"数据库文件不存在");
        return NO;
    }

}

- (BOOL)insertDataWithAPIName:(NSString *)apiName dictData:(NSDictionary *)response
{
    if (![self getPhoneStr]) {
        return NO;
    }
    if (!self.phoneDatabase) {
        return NO;
    }
    NSString *jsonString = [self dictionaryToJson:response];
    __block BOOL isSuccess = YES;
    [self.phoneDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count == 0) {
                    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (datas Text)", apiName];
                    [db executeUpdate:sqlString];
                }
                NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM %@", apiName];
                rs = [db executeQuery:selectStr];
                if ([rs next]) {
                    NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ SET datas='%@'", apiName, jsonString];
                    BOOL isSuccess = [db executeUpdate:sqlString];
                    if (!isSuccess) {
                        NSLog(@"更新数据库文件失败");
                        isSuccess = NO;
                    }
                }else{
                    NSString *insertStr = [NSString stringWithFormat:@"INSERT INTO %@(datas) VALUES ('%@');", apiName, jsonString];
                    BOOL isSuccess = [db executeUpdate:insertStr];
                    if (!isSuccess) {
                        NSLog(@"插入数据库文件失败");
                        isSuccess = NO;
                    }
                }
                [rs close];
            }
            [db close];
        }else{
            isSuccess = NO;
        }
    }];
    return isSuccess;
}

- (BOOL)deleteTableWithAPIName:(NSString *)apiName {
    if (![self getPhoneStr]) {
        return NO;
    }
    if (!self.phoneDatabase) {
        return NO;
    }
    __block BOOL isSuccess = YES;
    [self.phoneDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *sqlString = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", apiName];
            BOOL isSuccess = [db executeUpdate:sqlString];
            if (!isSuccess) {
                NSLog(@"删除数据库文件失败");
                isSuccess = NO;
            }
            [db close];
        }else{
            isSuccess = NO;
        }
    }];
    return isSuccess;
}

- (NSDictionary *)getResponseWithAPIName:(NSString *)apiName
{
    if (![self getPhoneStr]) {
        return nil;
    }
    if (!self.phoneDatabase) {
        return nil;
    }
    //打开数据库
    __block NSDictionary *dict;
    [self.phoneDatabase inDatabase:^(FMDatabase *db) {
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                
                if (count == 1) {
                    NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@", apiName];
                    FMResultSet *nextRs = [db executeQuery:sqlString];
                    if ([nextRs next]) {
                        //如果能打开说明已存在,获取数据
                        NSString *jsonStr = [nextRs stringForColumn:@"datas"];
                        if (jsonStr) {
                            dict = [self jsonToDictionary:jsonStr];
                        }
                        [nextRs close];
                    }else{
                        dict = nil;
                    }
                }
                [rs close];
            }
            [db close];
        }

    }];
    
    return dict;
}

//插入一条数据
- (BOOL)insertDataWithAPIName:(NSString *)apiName stringData:(NSString *)string
{
    if (![self getPhoneStr]) {
        return NO;
    }
    if (!self.phoneDatabase) {
        return NO;
    }
    __block BOOL isSuccess = NO;
    [self.phoneDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count == 0) {
                    //                NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (datas Text)", apiName];
                    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (id integer PRIMARY KEY AUTOINCREMENT, data text NOT NULL)", apiName];
                    BOOL result = [db executeUpdate:sqlString];
                    if (result) {
                        NSLog(@"成功创表");
                    } else {
                        NSLog(@"创表失败");
                    }
                }
                
                NSString *selectData = [NSString stringWithFormat:@"select * from %@ where data='%@'", apiName,string];
                rs = [db executeQuery:selectData];
                if (![rs next] || !rs) {
                    NSLog(@"数据不存在,插入数据");
                    //插入数据
                    NSString *insertStr = [NSString stringWithFormat:@"INSERT INTO %@(data) VALUES ('%@');", apiName, string];
                    BOOL isSuccessInsert = [db executeUpdate:insertStr];
                    if (!isSuccessInsert) {
                        NSLog(@"插入数据库文件失败");
                    }
                    isSuccess = isSuccessInsert;
                }
                [rs close];
            }
            [db close];
        }else{
            isSuccess = NO;
        }

    }];
    return isSuccess;
}

- (BOOL)deleteDataWithAPIName:(NSString *)apiName stringData:(NSString *)string
{
    if (![self getPhoneStr]) {
        return NO;
    }
    if (!self.phoneDatabase) {
        return NO;
    }
    __block BOOL isSuccess = NO;
    [self.phoneDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count == 0) {
                    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (id integer PRIMARY KEY AUTOINCREMENT, data text NOT NULL)", apiName];
                    BOOL result = [db executeUpdate:sqlString];
                    if (result) {
                        NSLog(@"成功创表");
                    } else {
                        NSLog(@"创表失败");
                    }
                }
                NSString *selectData;
                if (string) {
                    selectData = [NSString stringWithFormat:@"delete from %@ where data='%@'", apiName,string];
                }else{
                    selectData = [NSString stringWithFormat:@"delete from %@",apiName];
                }
                BOOL isSuccessDel = [db executeUpdate:selectData];
                if (!isSuccessDel) {
                    NSLog(@"删除数据库文件失败");
                }
                isSuccess = isSuccessDel;
                [rs close];
            }
            [db close];
        }else{
            isSuccess = NO;
        }
    }];
    return isSuccess;
}

//插入多个黑名单列表数据
- (void)insertBlackListWithPhoneLists:(NSArray *)lists
{
    NSInteger successCount = 0;
    NSInteger failedCount = 0;
    for (NSDictionary *phoneDict in lists) {
        if ([self insertBlackListWithPhoneString:phoneDict[@"BlackNum"]]) {
            successCount++;
        }else{
            failedCount++;
        }
    }
    NSLog(@"黑名单总数%ld条---成功%ld条---失败%ld条", lists.count, successCount, failedCount);
}

//将数据逐条取出
- (NSArray *)getArrayResponseWithAPIName:(NSString *)apiName
{
    if (![self getPhoneStr]) {
        return [NSArray array];
    }
    if (!self.phoneDatabase) {
        return [NSArray array];
    }
    //打开数据库
    __block NSMutableArray *arrayDatas = [NSMutableArray array];
    [self.phoneDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count == 1) {
                    NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@", apiName];
                    FMResultSet *nextRs = [db executeQuery:sqlString];
                    while ([nextRs next]) {
                        NSString *dataStr = [nextRs stringForColumn:@"data"];
                        if (dataStr) {
                            [arrayDatas addObject:dataStr];
                        }
                    }
                    [nextRs close];
                }
                [rs close];
            }
            [db close];
        }
    }];
    return arrayDatas;
}

//插入黑名单数据
- (BOOL)insertBlackListWithPhoneString:(NSString *)string
{
    if (![self getPhoneStr]) {
        return NO;
    }
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", self.getPhoneStr];
    return [self insertDataWithAPIName:apiName stringData:string];
}

//删除黑名单数据
- (BOOL)deleteBlackListWithPhoneString:(NSString *)string
{
    if (![self getPhoneStr]) {
        return NO;
    }
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", self.getPhoneStr];
    return [self deleteDataWithAPIName:apiName stringData:string];
}

//清空黑名单数据
- (BOOL)deleteAllBlackLists
{
    if (![self getPhoneStr]) {
        return NO;
    }
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", self.getPhoneStr];
    return [self deleteDataWithAPIName:apiName stringData:nil];
}

//获取黑名单数据
- (NSArray *)getBlackLists
{
    if (![self getPhoneStr]) {
        return [NSArray array];
    }
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", self.getPhoneStr];
    return [self getArrayResponseWithAPIName:apiName];
}



//短信数据库
- (NSString *)msgRecordfilePath
{
    if ([self getPhoneStr]) {
        NSString *dataName = [NSString stringWithFormat:@"%@.db", [NSString stringWithFormat:@"%@_msgRecordDataName", self.getPhoneStr]];
        NSString *string = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *stringPath = [string stringByAppendingPathComponent:dataName];
        return stringPath;
    }
    return nil;
}
- (FMDatabaseQueue *)msgDatabase
{
    if (!_msgDatabase) {
        if ([self msgRecordfilePath]) {
            _msgDatabase = [FMDatabaseQueue databaseQueueWithPath:[self msgRecordfilePath]];
        }else{
            _msgDatabase = nil;
        }
    }
    return _msgDatabase;
}

#pragma mark --- 删除短信数据库(清空短信列表和所有短信)
//删除短信数据库(清空短信列表和所有短信)
- (BOOL)deleteMessageDatabase
{
    BOOL isSuccess = YES;
    //删除列表操作
    isSuccess = [self deleteMessageTableWithAPIName:@"MessageSessionList"] ? YES : NO;
    //删除短信操作
    isSuccess = [self deleteMessageTableWithAPIName:@"MessageContentList"] ? : NO;
    return isSuccess;
}

#pragma mark --- 获取短信列表最后一条的时间
//获取短信列表最后一条的时间
- (NSString *)getLastTimeWithMessageList
{
    if (![self getPhoneStr]) {
        return nil;
    }
    return [self getLastTimeWithMessageListWithApiName:@"MessageSessionList" isMessageContent:NO PhoneNumber:nil][@"timeString"];
}

#pragma mark --- 获取短信列表指定数据
//获取短信列表指定数据
- (NSDictionary *)getMessageListDataWithPhone:(NSString *)phone
{
    if (![self getPhoneStr]) {
        return nil;
    }
    return [self getMessageDataWithApiName:@"MessageSessionList" isMessageContent:NO PhoneNumber:phone SmsId:nil];
}

#pragma mark --- 获取指定页数的短信列表
//获取指定页数的短信列表
- (NSArray *)getMessageListsWithPage:(NSInteger)page
{
    if (![self getPhoneStr]) {
        return [NSArray array];
    }
    return [self getMessageListsWithPage:page apiName:@"MessageSessionList" isMessageContent:NO PhoneNumber:nil];
}

#pragma mark --- 插入短信列表
//插入短信列表
- (BOOL)insertMessageListWithMessageLists:(NSArray *)messageList
{
    if (![self getPhoneStr]) {
        return NO;
    }
    BOOL isSuccess = YES;
    for (NSDictionary *dict in messageList) {
        if (![self insertMessageListWithMessage:dict apiName:@"MessageSessionList" isMessageContent:NO PhoneNumber:nil]) {
            isSuccess = NO;
        }
    }
    return isSuccess;
}

#pragma mark --- 删除短信列表(需要同时删除列表所有短信)
//删除短信列表(需要同时删除列表所有短信)
- (BOOL)deteleMessageListWithPhoneLists:(NSArray *)phoneLists
{
    if (![self getPhoneStr]) {
        return NO;
    }
    if (!phoneLists || !phoneLists.count) {
        return NO;
    }
    BOOL isSuccess = YES;
    for (NSString *phone in phoneLists) {
        if (![self deleteMessageWithPhone:phone apiName:@"MessageSessionList"]) {
            isSuccess = NO;
        }
    }
    return isSuccess;
}

//删除短信操作
- (BOOL)deleteMessageWithPhone:(NSString *)phoneStr apiName:(NSString *)apiName
{
    if (![self getPhoneStr]) {
        return NO;
    }
    BOOL isSuccess = YES;
    //删除列表操作
    isSuccess = [self deleteMessageListWithPhone:phoneStr apiName:apiName] ? YES : NO;
    //删除短信操作
    isSuccess = [self deleteMessageContentWithPhone:phoneStr apiName:@"MessageContentList" SMSIDStr:nil] ? : NO;
    return isSuccess;
}

#pragma mark --- 获取联系人短信内容最后一条的时间
//获取联系人短信内容最后一条的时间
- (NSString *)getLastTimeMessageContentWithPhone:(NSString *)phone
{
    if (![self getPhoneStr]) {
        return nil;
    }
    return [self getLastTimeWithMessageListWithApiName:@"MessageContentList" isMessageContent:YES PhoneNumber:phone][@"timeString"];
}

#pragma mark --- 获取联系人短信内容最后一条的数据
//获取联系人短信内容最后一条的数据
- (NSDictionary *)getLastDataMessageContentWithPhone:(NSString *)phone
{
    if (![self getPhoneStr]) {
        return nil;
    }
    return [self getLastTimeWithMessageListWithApiName:@"MessageContentList" isMessageContent:YES PhoneNumber:phone][@"data"];
}

#pragma mark --- 获取指定页数的短信内容
//获取指定页数的短信内容
- (NSArray *)getMessageContentWithPage:(NSInteger)page Phone:(NSString *)phone
{
    if (![self getPhoneStr]) {
        return nil;
    }
    return [self getMessageListsWithPage:page apiName:@"MessageContentList" isMessageContent:YES PhoneNumber:phone];
}

#pragma mark --- 插入短信内容
//插入短信内容
- (BOOL)insertMessageContentWithMessageContent:(NSArray *)messageContents Phone:(NSString *)phone
{
    if (![self getPhoneStr]) {
        return NO;
    }
    BOOL isSuccess = YES;
    for (NSDictionary *dict in messageContents) {
        if (![self insertMessageListWithMessage:dict apiName:@"MessageContentList" isMessageContent:YES PhoneNumber:phone]) {
            isSuccess = NO;
        }
    }
    return isSuccess;
}

#pragma mark --- 删除指定短信内容(根据短信ID删除,如果短信已删除完成,需要删除短信列表)
//删除指定短信内容(根据短信ID删除,并且更新短信列表最后一条数据,如果短信已删除完成,需要删除短信列表)
- (BOOL)deteleMessageContentWithSMSIDLists:(NSArray *)smsIDLists WithPhone:(NSString *)phone
{
    if (![self getPhoneStr]) {
        return NO;
    }
    BOOL isSuccess = YES;
    for (NSString *smsId in smsIDLists) {
        if (![self deleteMessageContentWithPhone:phone apiName:@"MessageContentList" SMSIDStr:smsId]) {
            isSuccess = NO;
        }
    }
    
    if (![[self getMessageContentWithPage:0 Phone:phone] count] && phone) {
        //删除短信列表
        BOOL isdelete = [self deteleMessageListWithPhoneLists:@[phone]];
        if (!isdelete) {
            NSLog(@"删除指定短信后清空列表失败");
        }
    }else{
        //更新短信列表
        //最后一条短信内容
        NSDictionary *messageData = [self getLastDataMessageContentWithPhone:phone];
        //短信列表数据
        NSDictionary *messageListData = [self getMessageListDataWithPhone:phone];
        NSMutableDictionary *mutableMessageListData = [NSMutableDictionary dictionaryWithDictionary:messageListData];
        if (mutableMessageListData[@"SMSContent"] && messageData[@"SMSContent"] && ![mutableMessageListData[@"SMSContent"] isEqualToString:messageData[@"SMSContent"]]) {
            mutableMessageListData[@"SMSContent"] = messageData[@"SMSContent"];
            BOOL isInsertSuccess = [self insertMessageListWithMessageLists:@[mutableMessageListData]];
            if (isInsertSuccess) {
                NSLog(@"更新短信列表成功");
            }else{
                NSLog(@"更新短信列表失败");
            }
        }
    }
    return isSuccess;
}

#pragma mark --- 更新指定短信状态
//更新指定短信状态
- (BOOL)updateMessageStatuWithSMSIDDictArray:(NSArray<NSDictionary *> *)smsIds
{
    if (![self getPhoneStr]) {
        return NO;
    }
    BOOL isSuccess = YES;
    for (NSDictionary *dict in smsIds) {
        if (![self updateMessageStatuWithDict:dict apiName:@"MessageContentList" isMessageContent:YES PhoneNumber:nil]) {
            isSuccess = NO;
        }
    }
    return isSuccess;
}


#pragma mark ===================================== 删除数据库操作
//删除数据库表操作
- (BOOL)deleteMessageTableWithAPIName:(NSString *)apiName
{
    if (![self getPhoneStr]) {
        return NO;
    }
    if (!self.msgDatabase) {
        return NO;
    }
    __block BOOL isSuccess = YES;
    [self.msgDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *sqlString = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", apiName];
            BOOL isSuccess = [db executeUpdate:sqlString];
            if (!isSuccess) {
                UNLogLBEProcess(@"删除短信数据库文件失败")
                isSuccess = NO;
            }
            [db close];
        }else{
            isSuccess = NO;
        }
    }];
    return isSuccess;
}

#pragma mark ===================================== 获取最后一条数据时间操作
- (NSDictionary *)getLastTimeWithMessageListWithApiName:(NSString *)apiName isMessageContent:(BOOL)isContent PhoneNumber:(NSString *)phoneNumber
{
    //    FMDatabaseQueue *database = isContent ? self.msgContentDatabase : self.msgDatabase;
    if (!self.msgDatabase) {
        return nil;
    }
    __block NSDictionary *msgData = nil;
    [self.msgDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count != 0) {
                    NSString *selectStr;
                    if (isContent) {
                        selectStr = [NSString stringWithFormat:@"select * from %@ where contactnumber='%@' order by msgtime desc limit 0,1", apiName, phoneNumber];
                    }else{
                        selectStr = [NSString stringWithFormat:@"select * from %@ order by msgtime desc limit 0,1", apiName];
                    }
                    rs = [db executeQuery:selectStr];
                    if ([rs next]) {
                        NSString *timeStr = [rs stringForColumn:@"msgtime"];
                        NSString *dataStr = [rs stringForColumn:@"data"];
                        NSDictionary *dataDict = [self jsonToDictionary:dataStr];
                        msgData = @{@"timeString":timeStr, @"data" : dataDict};
                        NSLog(@"msgData--%@", msgData);
                    }else{
                        NSLog(@"没有查询到条目");
                    }
                }else{
                    NSLog(@"没有查询到表");
                }
                [rs close];
            }
            [db close];
        }
    }];
    return msgData;
}


#pragma mark ===================================== 根据指定ID获取短信内容
/**
 根据指定ID获取短信内容

 @param apiName 表名
 @param isContent 是否为短信内容
 @param phoneNumber 号码
 @param smsId 短信内容ID
 @return 数据
 */
- (NSDictionary *)getMessageDataWithApiName:(NSString *)apiName isMessageContent:(BOOL)isContent PhoneNumber:(NSString *)phoneNumber SmsId:(NSString *)smsId
{
    //    FMDatabaseQueue *database = isContent ? self.msgContentDatabase : self.msgDatabase;
    if (!self.msgDatabase) {
        return nil;
    }
    NSString *otherPhone;
    if (isContent) {
        otherPhone = smsId;
    }else{
        otherPhone = phoneNumber;
    }
    __block NSDictionary *msgData = nil;
    [self.msgDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count != 0) {
                    NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM %@ where id='%@'", apiName, otherPhone];
                    rs = [db executeQuery:selectStr];
                    if ([rs next]) {
                        NSString *dataStr = [rs stringForColumn:@"data"];
                        msgData = [self jsonToDictionary:dataStr];
                    }else{
                        NSLog(@"没有查询到条目");
                    }

//                    if (isContent) {
//                        selectStr = [NSString stringWithFormat:@"select * from %@ where contactnumber='%@'", apiName, phoneNumber];
//                        aaaa
//                    }else{
//                        selectStr = [NSString stringWithFormat:@"select * from %@ order by msgtime desc limit 0,1", apiName];
//                    }
//                    rs = [db executeQuery:selectStr];
//                    if ([rs next]) {
//                        NSString *timeStr = [rs stringForColumn:@"msgtime"];
//                        NSString *dataStr = [rs stringForColumn:@"data"];
//                        NSDictionary *dataDict = [self jsonToDictionary:dataStr];
//                        msgData = @{@"timeString":timeStr, @"data" : dataDict};
//                        NSLog(@"msgData--%@", msgData);
//                    }else{
//                        NSLog(@"没有查询到条目");
//                    }
                }else{
                    NSLog(@"没有查询到表");
                }
                [rs close];
            }
            [db close];
        }
    }];
    return msgData;
}

#pragma mark ===================================== 根据页码获取短信操作
- (NSArray *)getMessageListsWithPage:(NSInteger)page apiName:(NSString *)apiName isMessageContent:(BOOL)isContent PhoneNumber:(NSString *)phoneNumber
{
    //    FMDatabaseQueue *database = isContent ? self.msgContentDatabase : self.msgDatabase;
    if (!self.msgDatabase) {
        return [NSMutableArray array];
    }
    //打开数据库
    __block NSMutableArray *arrayDatas = [NSMutableArray array];
    [self.msgDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count) {
                    NSString *selectStr;
                    if (isContent) {
                        selectStr = [NSString stringWithFormat:@"select * from %@ where contactnumber='%@' order by msgtime desc limit '%@','%@'", apiName, phoneNumber, @(page * MessagePageSize), @(MessagePageSize)];
                    }else{
                        selectStr = [NSString stringWithFormat:@"select * from %@ order by msgtime desc limit '%@','%@'", apiName, @(page * MessagePageSize), @(MessagePageSize)];
                    }
                    FMResultSet *nextRs = [db executeQuery:selectStr];
                    while ([nextRs next]) {
                        NSString *dataStr = [nextRs stringForColumn:@"data"];
                        NSDictionary *dataDict = [self jsonToDictionary:dataStr];
                        if (dataDict) {
                            [arrayDatas addObject:dataDict];
                        }
                    }
                    [nextRs close];
                }
                [rs close];
            }
            [db close];
        }
    }];
    return arrayDatas;
}

#pragma mark ===================================== 插入短信操作
- (BOOL)insertMessageListWithMessage:(NSDictionary *)messageDict apiName:(NSString *)apiName isMessageContent:(BOOL)isContent PhoneNumber:(NSString *)phoneNumber
{
    //    FMDatabaseQueue *database = isContent ? self.msgContentDatabase : self.msgDatabase;
    if (!self.msgDatabase) {
        return NO;
    }
    NSString *jsonString = [self dictionaryToJson:messageDict];
    NSString *otherPhone;
    NSString *contactNumber;
    
    if ([messageDict[@"IsSend"] boolValue]) {
        contactNumber = messageDict[@"To"];
    }else{
        contactNumber = messageDict[@"Fm"];
    }
    if (isContent) {
        otherPhone = messageDict[@"SMSID"];
    }else{
        otherPhone = contactNumber;
    }
    __block BOOL isSuccess = YES;
    [self.msgDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count == 0) {
                    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (id text PRIMARY KEY, msgtime TimeStamp NOT NULL, data text NOT NULL, contactnumber text NOT NULL, IsRead text NOT NULL)", apiName];
                    BOOL result = [db executeUpdate:sqlString];
                    if (result) {
                        NSLog(@"成功创表");
                    } else {
                        NSLog(@"创表失败");
                    }
                }
                NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM %@ where id='%@'", apiName, otherPhone];
                rs = [db executeQuery:selectStr];
                if ([rs next]) {
                    NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ SET data='%@',msgtime='%@',contactnumber='%@',IsRead='%@' where id='%@'",apiName,jsonString,messageDict[@"SMSTime"],contactNumber, messageDict[@"IsRead"],otherPhone];
                    BOOL isSuccess = [db executeUpdate:sqlString];
                    if (!isSuccess) {
                        NSLog(@"更新数据库文件失败");
                        isSuccess = NO;
                    }
                }else{
                    NSString *insertStr = [NSString stringWithFormat:@"INSERT INTO %@ (data, msgtime, id, contactnumber, IsRead) VALUES ('%@', '%@', '%@', '%@', '%@');", apiName, jsonString, messageDict[@"SMSTime"], otherPhone, contactNumber, messageDict[@"IsRead"]];
                    BOOL isSuccess = [db executeUpdate:insertStr];
                    if (!isSuccess) {
                        NSLog(@"插入数据库文件失败");
                        isSuccess = NO;
                    }
                }
                [rs close];
            }
            [db close];
        }else{
            isSuccess = NO;
        }
    }];
    return isSuccess;
}


#pragma mark ===================================== 删除短信列表
//删除列表
- (BOOL)deleteMessageListWithPhone:(NSString *)phoneStr apiName:(NSString *)apiName
{
    if (!self.msgDatabase) {
        return NO;
    }
    __block BOOL isSuccess = YES;
    [self.msgDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count) {
                    NSString *selectStr = [NSString stringWithFormat:@"DELETE FROM %@ where id='%@'", apiName, phoneStr];
                    BOOL isUpdateSuccess = [db executeUpdate:selectStr];
                    if (!isUpdateSuccess) {
                        NSLog(@"删除短信列表失败");
                        isSuccess = NO;
                    }
                }
                [rs close];
            }
            [db close];
        }else{
            isSuccess = NO;
        }
    }];
    return isSuccess;
}


#pragma mark ===================================== 删除短信内容
- (BOOL)deleteMessageContentWithPhone:(NSString *)phoneStr apiName:(NSString *)apiName SMSIDStr:(NSString *)smsId
{
    if (!self.msgDatabase) {
        return NO;
    }
    __block BOOL isSuccess = YES;
    [self.msgDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count) {
                    NSString *selectStr;
                    if (smsId) {
                        //删除单条短信内容
                        selectStr = [NSString stringWithFormat:@"DELETE FROM %@ where id='%@'", apiName, smsId];
                    }else{
                        //删除所有短信
                        if (phoneStr) {
                            selectStr = [NSString stringWithFormat:@"DELETE FROM %@ where contactnumber='%@'", apiName, phoneStr];
                        }
                    }
                    BOOL isUpdateSuccess = [db executeUpdate:selectStr];
                    if (!isUpdateSuccess) {
                        NSLog(@"删除短信失败");
                        isSuccess = NO;
                    }
                }
                [rs close];
            }
            [db close];
        }else{
            isSuccess = NO;
        }
    }];
    return isSuccess;
}


#pragma mark ===================================== 更新短信状态
- (BOOL)updateMessageStatuWithDict:(NSDictionary *)messageDict apiName:(NSString *)apiName isMessageContent:(BOOL)isContent PhoneNumber:(NSString *)phoneNumber
{
    if (!self.msgDatabase) {
        return NO;
    }
    NSString *smsID = messageDict[@"SMSID"];
    if (!smsID || !smsID.length) {
        return NO;
    }
    __block BOOL isSuccess = YES;
    [self.msgDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count == 0) {
                    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (id text PRIMARY KEY, msgtime TimeStamp NOT NULL, data text NOT NULL, contactnumber text NOT NULL, IsRead text NOT NULL)", apiName];
                    BOOL result = [db executeUpdate:sqlString];
                    if (result) {
                        NSLog(@"成功创表");
                    } else {
                        NSLog(@"创表失败");
                    }
                }
                NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM %@ where id='%@'", apiName, smsID];
                rs = [db executeQuery:selectStr];
                if ([rs next]) {
                    NSString *dataStr = [rs stringForColumn:@"data"];
                    NSDictionary *dataDict = [self jsonToDictionary:dataStr];
                    if (dataDict) {
                        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dataDict];
                        mutableDict[@"Status"] = messageDict[@"Status"];
                        dataStr = [self dictionaryToJson:mutableDict];
                    }
                    NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ SET data='%@' where id='%@'",apiName,dataStr,smsID];
                    BOOL isSuccess = [db executeUpdate:sqlString];
                    if (!isSuccess) {
                        NSLog(@"更新数据库文件失败");
                        isSuccess = NO;
                    }
                }
                [rs close];
            }
            [db close];
        }else{
            isSuccess = NO;
        }
    }];
    return isSuccess;
}

#pragma mark ===================================== 获取未读短信列表
- (NSArray *)getUnReadMessageList
{
    if (![self getPhoneStr]) {
        return [NSArray array];
    }
//    [self getMessageListsWithPage:page apiName:@"MessageSessionList" isMessageContent:NO PhoneNumber:nil];
    return [self getMessageListsWithApiName:@"MessageSessionList" isMessageContent:NO Key:@"IsRead" Value:@"0" PhoneNumber:nil];
}

#pragma mark ===================================== 根据指定Key获取短信操作
- (NSArray *)getMessageListsWithApiName:(NSString *)apiName isMessageContent:(BOOL)isContent Key:(NSString *)key Value:(id)value PhoneNumber:(NSString *)phoneNumber
{
    if (!self.msgDatabase) {
        return [NSMutableArray array];
    }
    //打开数据库
    __block NSMutableArray *arrayDatas = [NSMutableArray array];
    [self.msgDatabase inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count) {
                    NSString *selectStr;
                    if (isContent) {
                        selectStr = [NSString stringWithFormat:@"select * from %@ where contactnumber='%@' and %@='%@'", apiName, phoneNumber, key, value];
                    }else{
                        selectStr = [NSString stringWithFormat:@"select * from %@ where %@='%@'", apiName, key, value];
                    }
                    FMResultSet *nextRs = [db executeQuery:selectStr];
                    while ([nextRs next]) {
                        NSString *dataStr = [nextRs stringForColumn:@"data"];
                        NSDictionary *dataDict = [self jsonToDictionary:dataStr];
                        if (dataDict) {
                            [arrayDatas addObject:dataDict];
                        }
                    }
                    [nextRs close];
                }
                [rs close];
            }
            [db close];
        }
    }];
    return arrayDatas;
}


#pragma mark ---- 字典转JSON
- (NSString *)dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    if (parseError) {
        return @"";
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}

#pragma mark ---- JSON转字典
- (NSDictionary *)jsonToDictionary:(NSString *)jsonStr
{
    NSError *parseError = nil;
    NSData *jsonData1 = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dataDict=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingMutableContainers error:&parseError];
    if (parseError) {
        return nil;
    }
    return dataDict;
}

@end
