//
//  UNConvertFormatTool.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNConvertFormatTool.h"

@implementation UNConvertFormatTool

//NSDate转NSString(年月日)
+ (NSString *)dateStringYMDFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日"];
    NSString *currentDateString = [dateFormatter stringFromDate:date];
    NSLog(@"%@",currentDateString);
    return currentDateString;
}

//NSDate转NSString(年月日时分)
+ (NSString *)dateStringFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日 HH:mm"];
    NSString *currentDateString = [dateFormatter stringFromDate:date];
    NSLog(@"%@",currentDateString);
    return currentDateString;
}

//NSDate转NSString(年-月-日-时:分:秒)
+ (NSString *)dateStringFromDate2:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentDateString = [dateFormatter stringFromDate:date];
    NSLog(@"%@",currentDateString);
    return currentDateString;
}
//NSDate转NSString(月日时分)
+ (NSString *)dateStringFromDate3:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM月dd日 HH:mm"];
    NSString *currentDateString = [dateFormatter stringFromDate:date];
    NSLog(@"%@",currentDateString);
    return currentDateString;
}

//NSString转NSDate
+ (NSDate *)dateFromDateString:(NSString *)string
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date=[formatter dateFromString:string];
    return date;
}
//NSDateString转指定格式的NSString
+ (NSString *)stringFromDateString:(NSString *)dateString
{
    NSDate *date = [self dateFromDateString:dateString];
    return [self dateStringFromDate:date];
}


#pragma mark ---- 字典转JSON
+ (NSString *)objectToJson:(id)object
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&parseError];
    if (parseError) {
        return @"";
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}

#pragma mark ---- JSON转字典
+ (id)jsonToObject:(NSString *)jsonStr
{
    NSError *parseError = nil;
    NSData *jsonData1 = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    id dataDict=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingMutableContainers error:&parseError];
    if (parseError) {
        return nil;
    }
    return dataDict;
}

@end
