//
//  NSString+Utils.h
//  WeChatContacts-demo
//
//  Created by shen_gh on 16/3/12.
//  Copyright © 2016年 com.joinup(Beijing). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Utils)

/**
 *  汉字的拼音
 *
 *  @return 拼音
 */
- (NSString *)pinyin;

//去除空格
- (NSString *)removeSpace;

//汉字转拼音头部首字母
- (NSString *)pinyinHeader;

//拼音转九宫格数字
- (NSString *)pinyinToNumber;

@end
