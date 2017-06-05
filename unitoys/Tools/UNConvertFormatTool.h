//
//  UNConvertFormatTool.h
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

//转换格式工具类
@interface UNConvertFormatTool : NSObject

//NSDate转NSString(年月日)
+ (NSString *)dateStringYMDFromDate:(NSDate *)date;

//NSDate转NSString(年月日时分)
+ (NSString *)dateStringFromDate:(NSDate *)date;

//NSDate转NSString(年-月-日-时:分:秒)
+ (NSString *)dateStringFromDate2:(NSDate *)date;

//NSDate转NSString(月日时分)
+ (NSString *)dateStringFromDate3:(NSDate *)date;

//NSString转NSDate
+ (NSDate *)dateFromDateString:(NSString *)string;

//NSDateString转指定格式的NSString
+ (NSString *)stringFromDateString:(NSString *)dateString;

//判断字符串是否全为数字
+ (BOOL)isAllNumberWithString:(NSString *)str;

////字典转JSON
//+ (NSString *)dictionaryToJson:(NSDictionary *)dic;
////JSON转字典
//+ (NSDictionary *)jsonToDictionary:(NSString *)jsonStr;

+ (NSString *)checkLinkNameWithPhoneStr:(NSString *)phoneStr;

//id转JSON
+ (NSString *)objectToJson:(id)object;
//JSON转id
+ (id)jsonToObject:(NSString *)jsonStr;

@end
