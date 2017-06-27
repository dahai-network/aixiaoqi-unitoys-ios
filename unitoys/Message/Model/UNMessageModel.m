//
//  UNMessageModel.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/26.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNMessageModel.h"
#import "UNDataTools.h"

@implementation UNMessageModel

+ (UNMessageModel *)modelWithDict:(NSDictionary *)dict
{
    UNMessageModel *model = [UNMessageModel mj_objectWithKeyValues:dict];
    return model;
}

- (void)setSMSTime:(NSString *)SMSTime
{
    if (SMSTime) {
        _SMSTime = [[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:SMSTime];
    }else{
        _SMSTime = SMSTime;
    }
}

- (MJMessageType)type
{
    if ([self IsSend]) {
        return MJMessageTypeMe;
    }else{
        return MJMessageTypeOther;
    }
}

@end
