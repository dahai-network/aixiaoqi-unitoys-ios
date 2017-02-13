//
//  NSString+Addition.m
//  IUClient
//
//  Created by xthc on 10/22/13.
//  Copyright (c) 2013 xthc. All rights reserved.
//

#import "NSString+Addition.h"

@implementation NSString (Addition)

-(BOOL)isContainOfString:(NSString *)aString
{
    NSRange  range = [self rangeOfString:aString];
    if (range.length > 0) {
        return YES;
    }
    return NO;
}

#pragma mark - 字符匹配
//是否是0 - 9 的数字
-(BOOL)isValidateEditNum
{
    NSString *numRegex = @"^[1-9]\\d*|0$";
    NSPredicate *numTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", numRegex];
    return [numTest evaluateWithObject:self];
}



#pragma mark - 判断邮箱和手机号码是否合法
/*邮箱验证 MODIFIED BY HELENSONG*/
-(BOOL)isValidateEmail
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

/*手机号码验证 MODIFIED BY HELENSONG*/
-(BOOL) isValidateMobile
{
    //手机号以13， 15，18开头，八个 \d 数字字符
    NSString *phoneRegex = @"^((13[0-9])|(15[^4,\\D])|(18[0,0-9]))\\d{8}$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",phoneRegex];
    //    NSLog(@"phoneTest is %@",phoneTest);
    return [phoneTest evaluateWithObject:self];
}

/*密码验证6~18位字符*/
- (BOOL)isValidatePassWord {
    NSString *passWordRegex = @"^[a-zA-Z0-9]{6,18}+$";
    NSPredicate *passWordPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",passWordRegex];
    return [passWordPredicate evaluateWithObject:self];
}

/*身份证号码验证*******/
-(BOOL)isValidateSFZ
{
    NSString * sfzRegex = @"\\d{15}|\\d{18}";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",sfzRegex];
    //    NSLog(@"phoneTest is %@",phoneTest);
    return [phoneTest evaluateWithObject:self];
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

@end
