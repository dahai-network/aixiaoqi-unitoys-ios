//
//  UnMessageLinkManModel.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UnMessageLinkManModel.h"
#import "UNConvertFormatTool.h"

@implementation UnMessageLinkManModel

- (instancetype)initWithPhone:(NSString *)phone
{
    if (self = [super init]) {
        [self getDataWithPhone:phone];
    }
    return self;
}

- (instancetype)initWithPhone:(NSString *)phone LinkMan:(NSString *)linkMan
{
    if (self = [super init]) {
        [self getDataWithPhone:phone LinkMan:linkMan];
    }
    return self;
}

- (void)getDataWithPhone:(NSString *)phone
{
    NSString *checkPhone = [self checkNumberWithPhone:phone];
    if (checkPhone) {
        self.phoneNumber = checkPhone;
        self.linkManName = [self getLinkManNameWithPhone:checkPhone];
    }
}

- (void)getDataWithPhone:(NSString *)phone LinkMan:(NSString *)linkMan
{
    NSString *checkPhone = [self checkNumberWithPhone:phone];
    if (checkPhone) {
        self.phoneNumber = checkPhone;
    }
    if (linkMan) {
        self.linkManName = linkMan;
    }else{
        self.linkManName = [self.phoneNumber copy];
    }
}

- (NSString *)getLinkManNameWithPhone:(NSString *)phone
{
    NSString *linkMan = [UNConvertFormatTool checkLinkNameWithPhoneStr:phone];
    if (linkMan) {
        return linkMan;
    }else{
        return phone;
    }
}

- (NSString *)checkNumberWithPhone:(NSString *)phoneStr
{
    if ([phoneStr containsString:@"-"]) {
       phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
    }
    if ([phoneStr containsString:@" "]) {
        phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    if ([phoneStr containsString:@"+86"]) {
        phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"+86" withString:@""];
    }
    if ([phoneStr containsString:@"#"]) {
        phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"#" withString:@""];
    }
    if ([phoneStr containsString:@","]) {
        phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"," withString:@""];
    }
    return phoneStr;
}

@end
