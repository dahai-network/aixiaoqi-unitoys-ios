//
//  UNDatabaseTools.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/1.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNDatabaseTools.h"

@interface UNDatabaseTools()

@property (nonatomic, copy) NSString *filePath;
//@property (nonatomic, strong) FMDatabase *database;

@end

static FMDatabaseQueue *_database =nil;
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

- (FMDatabaseQueue *)database
{
    if (!_database) {
//        _database = [FMDatabase databaseWithPath:[self filePath]];
        if ([self filePath]) {
            _database = [FMDatabaseQueue databaseQueueWithPath:[self filePath]];
        }else{
            _database = nil;
        }
    }
    return _database;
}

- (NSString *)filePath
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
    if (!self.database) {
        return NO;
    }
    NSString *jsonString = [self dictionaryToJson:response];
    __block BOOL isSuccess = YES;
    [self.database inDatabase:^(FMDatabase *db) {
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
    if (!self.database) {
        return NO;
    }
    __block BOOL isSuccess = YES;
    [self.database inDatabase:^(FMDatabase *db) {
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
    if (!self.database) {
        return nil;
    }
    //打开数据库
    __block NSDictionary *dict;
    [self.database inDatabase:^(FMDatabase *db) {
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
    if (!self.database) {
        return NO;
    }
    __block BOOL isSuccess = NO;
    [self.database inDatabase:^(FMDatabase *db) {
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
    if (!self.database) {
        return NO;
    }
    __block BOOL isSuccess = NO;
    [self.database inDatabase:^(FMDatabase *db) {
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
    if (!self.database) {
        return [NSMutableArray array];
    }
    //打开数据库
    __block NSMutableArray *arrayDatas = [NSMutableArray array];
    [self.database inDatabase:^(FMDatabase *db) {
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
