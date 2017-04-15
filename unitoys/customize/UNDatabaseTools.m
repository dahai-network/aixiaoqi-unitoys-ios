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
@property (nonatomic, strong) FMDatabase *database;

@end

@implementation UNDatabaseTools

+ (instancetype)sharedFMDBTools
{
    static UNDatabaseTools *databaseTool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        databaseTool = [[UNDatabaseTools alloc] init];
    });
    return databaseTool;
}

- (FMDatabase *)database
{
    if (!_database) {
        _database = [FMDatabase databaseWithPath:[self filePath]];
    }
    return _database;
}

- (NSString *)filePath
{
    NSString *dataName = [NSString stringWithFormat:@"%@.db", [NSString stringWithFormat:@"%@_dataName", [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"][@"Tel"]]];
    NSString *string = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *stringPath = [string stringByAppendingPathComponent:dataName];
    return stringPath;
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
    NSString *jsonString = [self dictionaryToJson:response];
    BOOL isSuccess = YES;
        //打开数据库
        if ([self.database open]) {
            NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
            FMResultSet *rs = [self.database executeQuery:existsSql];
            if ([rs next]) {
                NSInteger count = [rs intForColumn:@"countNum"];
                if (count == 0) {
                    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (datas Text)", apiName];
                    [self.database executeUpdate:sqlString];
                }
                NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM %@", apiName];
                rs = [self.database executeQuery:selectStr];
                if ([rs next]) {
                    NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ SET datas='%@'", apiName, jsonString];
                    BOOL isSuccess = [self.database executeUpdate:sqlString];
                    if (!isSuccess) {
                        NSLog(@"更新数据库文件失败");
                        isSuccess = NO;
                    }
                }else{
                    NSString *insertStr = [NSString stringWithFormat:@"INSERT INTO %@(datas) VALUES ('%@');", apiName, jsonString];
                    BOOL isSuccess = [self.database executeUpdate:insertStr];
                    if (!isSuccess) {
                        NSLog(@"插入数据库文件失败");
                        isSuccess = NO;
                    }
                }
                [rs close];
            }
            [self.database close];
        }else{
            isSuccess = NO;
        }
    return isSuccess;
}

- (BOOL)deleteTableWithAPIName:(NSString *)apiName {
    BOOL isSuccess = YES;
    //打开数据库
    if ([self.database open]) {
        NSString *sqlString = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", apiName];
        BOOL isSuccess = [self.database executeUpdate:sqlString];
        if (!isSuccess) {
            NSLog(@"删除数据库文件失败");
            isSuccess = NO;
        }
//        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
//        FMResultSet *rs = [self.database executeQuery:existsSql];
//        if ([rs next]) {
//            NSInteger count = [rs intForColumn:@"countNum"];
//            if (count == 0) {
//                NSLog(@"没有数据");
//            } else {
//                NSString *sqlString = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", apiName];
//                BOOL isSuccess = [self.database executeUpdate:sqlString];
//                if (!isSuccess) {
//                    NSLog(@"删除数据库文件失败");
//                    isSuccess = NO;
//                }
//            }
//            [rs close];
//        }
        [self.database close];
    }else{
        isSuccess = NO;
    }
    return isSuccess;
}

- (NSDictionary *)getResponseWithAPIName:(NSString *)apiName
{
    //打开数据库
    NSDictionary *dict;
    if ([self.database open]) {
        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
        FMResultSet *rs = [self.database executeQuery:existsSql];
        if ([rs next]) {
            NSInteger count = [rs intForColumn:@"countNum"];
            
            if (count == 1) {
                NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@", apiName];
//                rs = [self.database executeQuery:sqlString];
                FMResultSet *nextRs = [self.database executeQuery:sqlString];
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
        [self.database close];
    }
    return dict;
}

//插入一条数据
- (BOOL)insertDataWithAPIName:(NSString *)apiName stringData:(NSString *)string
{
    BOOL isSuccess = NO;
    //打开数据库
    if ([self.database open]) {
        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
        FMResultSet *rs = [self.database executeQuery:existsSql];
        if ([rs next]) {
            NSInteger count = [rs intForColumn:@"countNum"];
            if (count == 0) {
//                NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (datas Text)", apiName];
                NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (id integer PRIMARY KEY AUTOINCREMENT, data text NOT NULL)", apiName];
                BOOL result = [self.database executeUpdate:sqlString];
                if (result) {
                    NSLog(@"成功创表");
                } else {
                    NSLog(@"创表失败");
                }
            }
            
            NSString *selectData = [NSString stringWithFormat:@"select * from %@ where data='%@'", apiName,string];
            rs = [self.database executeQuery:selectData];
            if (![rs next] || !rs) {
                NSLog(@"数据不存在,插入数据");
                //插入数据
                NSString *insertStr = [NSString stringWithFormat:@"INSERT INTO %@(data) VALUES ('%@');", apiName, string];
                BOOL isSuccessInsert = [self.database executeUpdate:insertStr];
                if (!isSuccessInsert) {
                    NSLog(@"插入数据库文件失败");
                }
                isSuccess = isSuccessInsert;
            }
            [rs close];
        }
        [self.database close];
    }else{
        isSuccess = NO;
    }
    return isSuccess;
}

- (BOOL)deleteDataWithAPIName:(NSString *)apiName stringData:(NSString *)string
{
    BOOL isSuccess = NO;
    //打开数据库
    if ([self.database open]) {
        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
        FMResultSet *rs = [self.database executeQuery:existsSql];
        if ([rs next]) {
            NSInteger count = [rs intForColumn:@"countNum"];
            if (count == 0) {
                NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE %@ (id integer PRIMARY KEY AUTOINCREMENT, data text NOT NULL)", apiName];
                BOOL result = [self.database executeUpdate:sqlString];
                if (result) {
                    NSLog(@"成功创表");
                } else {
                    NSLog(@"创表失败");
                }
            }
            
            NSString *selectData = [NSString stringWithFormat:@"delete from %@ where data='%@'", apiName,string];
            BOOL isSuccessDel = [self.database executeUpdate:selectData];
            if (!isSuccessDel) {
                NSLog(@"删除数据库文件失败");
            }
            isSuccess = isSuccessDel;
            
//            if ([rs next]) {
//                NSLog(@"数据存在,删除数据");
//                //插入数据
//                NSString *insertStr = [NSString stringWithFormat:@"INSERT INTO %@(data) VALUES ('%@');", apiName, string];
//                BOOL isSuccessInsert = [self.database executeUpdate:insertStr];
//                if (!isSuccessInsert) {
//                    NSLog(@"插入数据库文件失败");
//                }
//                isSuccess = isSuccessInsert;
//            }
            [rs close];
        }
        [self.database close];
    }else{
        isSuccess = NO;
    }
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
    //打开数据库
    NSMutableArray *arrayDatas = [NSMutableArray array];
    if ([self.database open]) {
        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", apiName];
        FMResultSet *rs = [self.database executeQuery:existsSql];
        if ([rs next]) {
            NSInteger count = [rs intForColumn:@"countNum"];
            if (count == 1) {
                NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@", apiName];
                FMResultSet *nextRs = [self.database executeQuery:sqlString];
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
        [self.database close];
    }
    return arrayDatas;
}




//插入黑名单数据
- (BOOL)insertBlackListWithPhoneString:(NSString *)string
{
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"][@"Tel"]];
    return [self insertDataWithAPIName:apiName stringData:string];
}

//删除黑名单数据
- (BOOL)deleteBlackListWithPhoneString:(NSString *)string
{
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"][@"Tel"]];
    return [self deleteDataWithAPIName:apiName stringData:string];
}

//获取黑名单数据
- (NSArray *)getBlackLists
{
    NSString *apiName = [NSString stringWithFormat:@"BlackList%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"][@"Tel"]];
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
