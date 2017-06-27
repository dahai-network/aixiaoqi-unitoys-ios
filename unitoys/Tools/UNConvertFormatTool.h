//
//  UNConvertFormatTool.h
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ContactModel;

//转换格式工具类
@interface UNConvertFormatTool : NSObject

//时间戳转NSString(年月日)
+ (NSString *)dateStringYMDFromTimeInterval:(NSString *)timeString;

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

//从字符串中提取数字
+ (NSString *)getNumStringWithString:(NSString *)str;

////字典转JSON
//+ (NSString *)dictionaryToJson:(NSDictionary *)dic;
////JSON转字典
//+ (NSDictionary *)jsonToDictionary:(NSString *)jsonStr;

//通过号码获取昵称
+ (NSString *)checkLinkNameWithPhoneStr:(NSString *)phoneStr;

//短信去除重复组名
+ (NSString *)checkLinkNameWithPhoneStrMergeGroupName:(NSString *)phoneStr;

//短信不显示组名
+ (NSString *)checkLinkNameWithPhoneStrNoGroupName:(NSString *)phoneStr;

//获取联系人信息
+ (ContactModel *)checkContactModelWithPhoneStr:(NSString *)phoneStr;

//去除号码中的特殊字符("-"," ","+86","#","(",")")
+ (NSString *)checkPhoneNumberSpecialString:(NSString *)phoneStr;

//seconds->@"00:00"
+ (NSString *)minSecWithSeconds:(int)seconds;

//16进制字符串转普通字符串
+ (NSString *)stringFromHexString:(NSString *)hexString;



//id转JSON
+ (NSString *)objectToJson:(id)object;
//JSON转id
+ (id)jsonToObject:(NSString *)jsonStr;

//获取数据类型
+ (NSString *)mimeTypeForData:(NSData *)data;

//重置第一页数据
+ (NSDictionary *)firstPageParamDictionry:(NSDictionary *)dic;

//转换下一页数据
+ (NSDictionary *)nextPageParamDictionry:(NSDictionary *)dic WithPage:(NSInteger)page;

@end
