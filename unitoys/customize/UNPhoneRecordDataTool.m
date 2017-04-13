//
//  UNPhoneRecordDataTool.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNPhoneRecordDataTool.h"
#import <FMDB/FMDB.h>

@interface UNPhoneRecordDataTool()

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) FMDatabase *database;

@end

@implementation UNPhoneRecordDataTool

+ (instancetype)sharedPhoneRecordDataTool
{
    static UNPhoneRecordDataTool *phoneRecordDataTool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        phoneRecordDataTool = [[UNPhoneRecordDataTool alloc] init];
    });
    return phoneRecordDataTool;
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
    NSString *dataName = @"callrecord2.db";
    NSString *string = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *stringPath = [string stringByAppendingPathComponent:dataName];
    return stringPath;
}

- (NSArray *)getRecordsWithPhoneNumber:(NSString *)phoneNumber
{
    NSMutableArray *records = [NSMutableArray array];
    if (![self.database open]) {
        NSLog(@"获取通话记录失败");
    }else{
        //监测数据库中我要需要的表是否已经存在
        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord" ];
        FMResultSet *rs = [self.database executeQuery:existsSql];
        if ([rs next]) {
            NSInteger count = [rs intForColumn:@"countNum"];
            NSLog(@"The table count: %li", count);
            if (count == 1) {
                NSLog(@"log_keepers table is existed.");
                //升序,将数据插入到最前面,因此最先插入的显示在最后
                NSString *dataSql = @"select * from CallRecord order by calltime asc";
                FMResultSet *rs = [self.database executeQuery:dataSql];
                while ([rs next]) {
                    //添加数据到arrPhoneCallRecord
                    //                    (datas, calltime, dataid)
                    NSString *jsonStr1 = [rs stringForColumn:@"datas"];
                    NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
                    NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
                    [records insertObject:dataArray atIndex:0];
                }
            }
            
            NSLog(@"log_keepers is not existed.");
        }else{
            NSLog(@"没有获取到通话记录数据------");
//            //加载数据到列表
//            //升序,将数据插入到最前面,因此最先插入的显示在最后
//            NSString *dataSql = @"select * from CallRecord order by calltime asc";
//            FMResultSet *rs = [db executeQuery:dataSql];
//            
//            while ([rs next]) {
//                //添加数据到arrPhoneCallRecord
//                NSString *jsonStr1 = [rs stringForColumn:@"datas"];
//                NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
//                NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
//                
//                [self.arrPhoneRecord insertObject:dataArray atIndex:0];
//            }
        }
        [rs close];
        [self.database close];
    }
    return [self getMatchingRecordsAllRecords:records WithPhone:phoneNumber];
}

- (NSArray *)getMatchingRecordsAllRecords:(NSArray *)array WithPhone:(NSString *)phone
{
    NSMutableArray *records = [NSMutableArray array];
    for (NSArray *temArray in array) {
        NSDictionary *dict = temArray.firstObject;
        if ([dict[@"hostnumber"] isEqualToString:phone] && [dict[@"calltype"] isEqualToString:@"来电"]) {
            [records addObject:temArray];
        }else if ([dict[@"destnumber"] isEqualToString:phone] && [dict[@"calltype"] isEqualToString:@"去电"]){
            [records addObject:temArray];
        }
    }
    return records;
}

@end
