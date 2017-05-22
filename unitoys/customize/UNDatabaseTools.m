//
//  UNDatabaseTools.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/1.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNDatabaseTools.h"

@interface UNDatabaseTools()

@property (nonatomic, copy) NSString *phoneRecordfilePath;
@property (nonatomic, copy) NSString *msgRecordfilePath;
@property (nonatomic, copy) NSString *msgContentfilePath;
//@property (nonatomic, strong) FMDatabase *database;

@end

static FMDatabaseQueue *_phoneDatabase =nil;
static FMDatabaseQueue *_msgDatabase =nil;
static FMDatabaseQueue *_msgContentDatabase =nil;
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
    if (self.getPhoneStr) {
        NSString *dataName = [NSString stringWithFormat:@"%@.db", [NSString stringWithFormat:@"%@_dataName", self.getPhoneStr]];
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
                    //                rs = [self.database executeQuery:sqlString];
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


//[self.database inDatabase:^(FMDatabase *db) {
//    //打开数据库
//}];

//插入一条数据
- (BOOL)insertDataWithAPIName:(NSString *)apiName stringData:(NSString *)string
{
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
    if (!self.phoneDatabase) {
        return [NSMutableArray array];
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
    if (!self.getPhoneStr) {
        return NO;
    }
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", self.getPhoneStr];
    return [self insertDataWithAPIName:apiName stringData:string];
}

//删除黑名单数据
- (BOOL)deleteBlackListWithPhoneString:(NSString *)string
{
    if (!self.getPhoneStr) {
        return NO;
    }
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", self.getPhoneStr];
    return [self deleteDataWithAPIName:apiName stringData:string];
}

//清空黑名单数据
- (BOOL)deleteAllBlackLists
{
    if (!self.getPhoneStr) {
        return NO;
    }
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", self.getPhoneStr];
    return [self deleteDataWithAPIName:apiName stringData:nil];
}

//获取黑名单数据
- (NSArray *)getBlackLists
{
    if (!self.getPhoneStr) {
        return [NSArray array];
    }
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", self.getPhoneStr];
    return [self getArrayResponseWithAPIName:apiName];
}



//短信数据库
- (NSString *)msgRecordfilePath
{
    if (self.getPhoneStr) {
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

//获取短信列表最后一条的时间
- (NSString *)getLastTimeWithMessageList
{
    return [self getLastTimeWithMessageListWithApiName:@"MessageSessionList" isMessageContent:NO];
}
//获取指定页数的短信列表
- (NSArray *)getMessageListsWithPage:(NSInteger)page
{
    return [self getMessageListsWithPage:page apiName:@"MessageSessionList" isMessageContent:NO];
}
//插入短信列表
- (BOOL)insertMessageListWithMessageLists:(NSArray *)messageList
{
    BOOL isSuccess = YES;
    for (NSDictionary *dict in messageList) {
        if (![self insertMessageListWithMessage:dict apiName:@"MessageSessionList" isMessageContent:NO]) {
            isSuccess = NO;
        }
    }
    return isSuccess;
}


- (NSString *)getLastTimeWithMessageListWithApiName:(NSString *)apiName isMessageContent:(BOOL)isContent
{
    FMDatabaseQueue *database = isContent ? self.msgContentDatabase : self.msgDatabase;
    if (!database) {
        return nil;
    }
    __block NSString *timeString = nil;
    [database inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count != 0) {
//                    NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM %@ where id='%@'", apiName, messageDict[@"msgId"]];
//                    rs = [db executeQuery:selectStr];
//                    @"select * from CallRecord order by calltime desc limit 0,1"
                    NSString *selectStr = [NSString stringWithFormat:@"select * from %@ order by msgtime desc limit 0,1", apiName];
                    rs = [db executeQuery:selectStr];
                    if ([rs next]) {
                        timeString = [rs stringForColumn:@"msgtime"];
                        NSLog(@"timeString--%@", timeString);
//                        NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ SET data='%@' msgtime='%@' where id='%@'", apiName, jsonString,messageDict[@"msgTime"] ,messageDict[@"msgId"]];
//                        BOOL isSuccess = [db executeUpdate:sqlString];
//                        if (!isSuccess) {
//                            NSLog(@"更新数据库文件失败");
//                            isSuccess = NO;
//                        }
                    }else{
                        NSLog(@"没有查询到条目");
                    }
                }else{
                    NSLog(@"没有查询到表");
//                    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (id text PRIMARY KEY, msgtime TimeStamp NOT NULL, data text NOT NULL)", apiName];
//                    BOOL result = [db executeUpdate:sqlString];
//                    if (result) {
//                        NSLog(@"成功创表");
//                    } else {
//                        NSLog(@"创表失败");
//                    }
                }
                [rs close];
            }
            [db close];
        }
    }];
    return timeString;
}

- (NSArray *)getMessageListsWithPage:(NSInteger)page apiName:(NSString *)apiName isMessageContent:(BOOL)isContent
{
    FMDatabaseQueue *database = isContent ? self.msgContentDatabase : self.msgDatabase;
    if (!database) {
        return [NSMutableArray array];
    }
    //打开数据库
    __block NSMutableArray *arrayDatas = [NSMutableArray array];
    [database inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count) {
//                    NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@", apiName];
//                    FMResultSet *nextRs = [db executeQuery:sqlString];
                    NSString *selectStr = [NSString stringWithFormat:@"select * from %@ order by msgtime desc limit '%@',20", apiName, @(page * 20)];
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

- (BOOL)insertMessageListWithMessage:(NSDictionary *)messageDict apiName:(NSString *)apiName isMessageContent:(BOOL)isContent
{
    FMDatabaseQueue *database = isContent ? self.msgContentDatabase : self.msgDatabase;
    if (!database) {
        return NO;
    }
    NSString *jsonString = [self dictionaryToJson:messageDict];
    NSString *otherPhone;
    if (isContent) {
        otherPhone = messageDict[@"SMSID"];
    }else{
        if ([messageDict[@"IsSend"] boolValue]) {
            otherPhone = messageDict[@"To"];
        }else{
            otherPhone = messageDict[@"Fm"];
        }
    }
    __block BOOL isSuccess = YES;
    [database inDatabase:^(FMDatabase *db) {
        //打开数据库
        if ([db open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [db executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count == 0) {
                    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (id text PRIMARY KEY, msgtime TimeStamp NOT NULL, data text NOT NULL)", apiName];
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
                    NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ SET data='%@' msgtime='%@' where id='%@'", apiName, jsonString,messageDict[@"SMSTime"] ,otherPhone];
                    BOOL isSuccess = [db executeUpdate:sqlString];
                    if (!isSuccess) {
                        NSLog(@"更新数据库文件失败");
                        isSuccess = NO;
                    }
                }else{
                    NSString *insertStr = [NSString stringWithFormat:@"INSERT INTO %@ (data, msgtime, id) VALUES ('%@', '%@', '%@');", apiName, jsonString, messageDict[@"SMSTime"], otherPhone];
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



//短信内容数据库
- (NSString *)msgContentfilePath
{
    if (self.getPhoneStr) {
        NSString *dataName = [NSString stringWithFormat:@"%@.db", [NSString stringWithFormat:@"%@_msgContentDataName", self.getPhoneStr]];
        NSString *string = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *stringPath = [string stringByAppendingPathComponent:dataName];
        return stringPath;
    }
    return nil;
}
- (FMDatabaseQueue *)msgContentDatabase
{
    if (!_msgContentDatabase) {
        if ([self msgContentfilePath]) {
            _msgContentDatabase = [FMDatabaseQueue databaseQueueWithPath:[self msgContentfilePath]];
        }else{
            _msgContentDatabase = nil;
        }
    }
    return _msgContentDatabase;
}
//获取联系人短信内容最后一条的时间
- (NSString *)getLastTimeMessageContentWithPhone:(NSString *)phone
{
    return [self getLastTimeWithMessageListWithApiName:phone isMessageContent:YES];
}
//获取指定页数的短信内容
- (NSArray *)getMessageContentWithPage:(NSInteger)page Phone:(NSString *)phone
{
    return [self getMessageListsWithPage:page apiName:phone isMessageContent:YES];
}
//插入短信内容
- (BOOL)insertMessageContentWithMessageContent:(NSArray *)messageContents Phone:(NSString *)phone
{
    BOOL isSuccess = YES;
    for (NSDictionary *dict in messageContents) {
        if (![self insertMessageListWithMessage:dict apiName:phone isMessageContent:YES]) {
            isSuccess = NO;
        }
    }
    return isSuccess;
}







- (NSString *)dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    if (parseError) {
        return @"";
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}

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
