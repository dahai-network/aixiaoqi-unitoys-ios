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

- (void)setName:(NSString *)name{
    if (name) {
        _name=name;
        _pinyinSpace = _name.pinyin;
        _pinyin=_pinyinSpace.removeSpace;
        _pinyinHeader = _pinyinSpace.pinyinHeader;
        _allPinyinNumber = _pinyin.pinyinToNumber;
        _headerPinyinNumber = _pinyinHeader.pinyinToNumber;
    }
}

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    if (phoneNumber) {
        NSString *phoneNum = [[phoneNumber copy] stringByReplacingOccurrencesOfString:@"-" withString:@""];
        _phoneNumber = [phoneNum stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
}

- (instancetype)initWithDic:(NSDictionary *)dic{
//    NSError *error;
//    self =  [self initWithDictionary:dic error:&error];
    if (self = [self init]) {
        self.portrait = dic[@"portrait"];
        self.phoneNumber = dic[@"phoneNumber"];
        self.thumbnailImageData = dic[@"thumbnailImageData"];
        self.name = dic[@"name"];
        if (dic[@"recordRefId"]) {
            self.recordRefId = [dic[@"recordRefId"] intValue];
        }
        if (dic[@"contactId"]) {
            self.contactId = dic[@"contactId"];
        }
    }
    return self;
}


//@property (nonatomic,copy) NSString <Optional>*portrait;
//@property (nonatomic,copy) NSString <Optional>*name;
//@property (nonatomic,copy) NSString <Optional>*pinyinSpace;//拼音(包含空格)
//@property (nonatomic,copy) NSString <Optional>*pinyin;//拼音(不包含空格)
//@property (nonatomic,copy) NSString <Optional>*pinyinHeader;//拼音头部
//
//@property (nonatomic,copy) NSString <Optional>*phoneNumber;
//
//@property (nonatomic,copy) NSString <Optional>*allPinyinNumber;//全拼音转九宫格键盘数字
//@property (nonatomic,copy) NSString <Optional>*headerPinyinNumber;//首字拼音转九宫格键盘数字
//
//@property (nonatomic,strong) NSData <Optional>*thumbnailImageData;//缩略头像


@end
