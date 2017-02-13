//
//  NSString+Addition.h
//  IUClient
//
//  Created by xthc on 10/22/13.
//  Copyright (c) 2013 xthc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Addition)

/**
 *  是否包含某段字符
 */
-(BOOL)isContainOfString:(NSString *)aString;
/**
 *  是否是0 - 9 的数字
 */
-(BOOL)isValidateEditNum;
/**
 *  邮箱验证
 */
-(BOOL)isValidateEmail;

/**
 *  手机号码验证
 */
-(BOOL) isValidateMobile;

/**
 *  身份证号码验证
 */
-(BOOL)isValidateSFZ;

/**
 *  密码验证
 */
- (BOOL)isValidatePassWord;

/**
 *  json串转化成字典
 *
 *  @param jsonString json串
 *
 *  @return 字典
 */
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

@end
