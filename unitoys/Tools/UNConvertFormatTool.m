//
//  UNConvertFormatTool.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNConvertFormatTool.h"

#import "ContactModel.h"
#import "AddressBookManager.h"

@implementation UNConvertFormatTool

//时间戳转NSString(年月日)
+ (NSString *)dateStringYMDFromTimeInterval:(NSString *)timeString
{
    NSTimeInterval time= [timeString doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *currentDateString = [dateFormatter stringFromDate:date];
    return currentDateString;
}

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

//判断字符串是否全为数字
+ (BOOL)isAllNumberWithString:(NSString *)str
{
    NSString * checkedNumString = [str stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    if(checkedNumString.length > 0) {
        return NO;
    }
    return YES;
    
//    NSString *regex = @"[0-9]*";
//    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
//    if ([pred evaluateWithObject:str]) {
//        return YES;
//    }
//    return NO;
}


//通过号码获取昵称
+ (NSString *)checkLinkNameWithPhoneStr:(NSString *)phoneStr
{
    NSString *linkName;
    if ([phoneStr containsString:@"-"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@" "]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@"+86"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"+86" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@"#"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"#" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@","]) {
        NSArray *arr = [phoneStr componentsSeparatedByString:@","];
        for (NSString *str in arr) {
            NSString *string;
            string = [self checkNameWithNumber:str];
            if (linkName) {
                linkName = [NSString stringWithFormat:@"%@,%@", linkName, string];
            } else {
                linkName = string;
            }
        }
    } else {
        linkName = [self checkNameWithNumber:phoneStr];
        return linkName;
    }
    return linkName;
}
+ (NSString *)checkNameWithNumber:(NSString *)number {
    ContactModel *tempModel;
    NSString *linkName = number;
    for (ContactModel *model in [AddressBookManager shareManager].dataArr) {
        tempModel = model;
        if ([model.phoneNumber containsString:@"-"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
        }
        if ([model.phoneNumber containsString:@" "]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
        }
        if ([model.phoneNumber containsString:@"+86"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"+86" withString:@""];
        }
        if ([model.phoneNumber containsString:@"#"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"#" withString:@""];
        }
        if ([model.phoneNumber containsString:@","]) {
            NSArray *phoneArr = [model.phoneNumber componentsSeparatedByString:@","];
            for (NSString *phoneStr in phoneArr) {
                if ([number isEqualToString:phoneStr]) {
                    linkName = tempModel.name;
                    break;
                }
            }
        }
        if ([number isEqualToString:[NSString stringWithFormat:@"%@", tempModel.phoneNumber]]) {
            linkName = tempModel.name;
            return linkName;
        }
        if ([number isEqualToString:@"anonymous"]) {
            linkName = @"未知";
            return linkName;
        }
    }
    return linkName;
}

//seconds->@"00:00"
+ (NSString *)minSecWithSeconds:(int)seconds
{
    NSString *callduration = @"00:00";
    if (seconds > 0) {
        int min = (int)seconds / 60;
        int sec = (int)seconds % 60;
        NSString *minStr;
        if (min < 10) {
            minStr = [NSString stringWithFormat:@"0%d",min];
        }else{
            minStr = [NSString stringWithFormat:@"%d",min];
        }
        callduration = [NSString stringWithFormat:@"%@:%02d", minStr, sec];
    }
    return callduration;
}

+ (NSString *)stringFromHexString:(NSString *)hexString
{
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:4];
    NSLog(@"------字符串=======%@",unicodeString);
    return unicodeString;
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

+ (NSString *)mimeTypeForData:(NSData *)data
{
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
            break;
        case 0x89:
            return @"image/png";
            break;
        case 0x47:
            return @"image/gif";
            break;
        case 0x49:
        case 0x4D:
            return @"image/tiff";
            break;
        case 0x25:
            return @"application/pdf";
            break;
        case 0xD0:
            return @"application/vnd";
            break;
        case 0x46:
            return @"text/plain";
            break;
        default:
            return @"application/octet-stream";
    }
    return nil;
}

@end
