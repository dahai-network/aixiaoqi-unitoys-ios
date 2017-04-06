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
