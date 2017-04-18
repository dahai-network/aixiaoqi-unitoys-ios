//
//  ContactModel.h
//  WeChatContacts-demo
//
//  Created by shen_gh on 16/3/12.
//  Copyright © 2016年 com.joinup(Beijing). All rights reserved.
//

#import "JSONModel.h"
//#import <AddressBook/AddressBook.h>

@interface ContactModel : JSONModel

@property (nonatomic,copy) NSString <Optional>*portrait;
@property (nonatomic,copy) NSString <Optional>*name;
@property (nonatomic,copy) NSString <Optional>*pinyinSpace;//拼音(包含空格)
@property (nonatomic,copy) NSString <Optional>*pinyin;//拼音(不包含空格)
@property (nonatomic,copy) NSString <Optional>*pinyinHeader;//拼音头部

@property (nonatomic,copy) NSString <Optional>*phoneNumber;

@property (nonatomic,copy) NSString <Optional>*allPinyinNumber;//全拼音转九宫格键盘数字
@property (nonatomic,copy) NSString <Optional>*headerPinyinNumber;//首字拼音转九宫格键盘数字

@property (nonatomic,strong) NSData <Optional>*thumbnailImageData;//缩略头像

@property (nonatomic, readwrite) int recordRefId;
@property (nonatomic, readwrite) NSString *contactId;

- (instancetype)initWithDic:(NSDictionary *)dic;

@end
