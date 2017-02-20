//
//  ContactModel.m
//  WeChatContacts-demo
//
//  Created by shen_gh on 16/3/12.
//  Copyright © 2016年 com.joinup(Beijing). All rights reserved.
//

#import "ContactModel.h"
#import "NSString+Utils.h"//category

@implementation ContactModel

- (void)setName:(NSString<Optional> *)name{
    if (name) {
        _name=name;
        _pinyinSpace = _name.pinyin;
        _pinyin=_pinyinSpace.removeSpace;
        _pinyinHeader = _pinyinSpace.pinyinHeader;
        _allPinyinNumber = _pinyin.pinyinToNumber;
        _headerPinyinNumber = _pinyinHeader.pinyinToNumber;
    }
}

- (void)setPhoneNumber:(NSString<Optional> *)phoneNumber
{
    if (phoneNumber) {
        NSString *phoneNum = [[phoneNumber copy] stringByReplacingOccurrencesOfString:@"-" withString:@""];
        _phoneNumber = [phoneNum stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
}

- (instancetype)initWithDic:(NSDictionary *)dic{
    NSError *error = nil;
    self =  [self initWithDictionary:dic error:&error];
    return self;
}

@end
