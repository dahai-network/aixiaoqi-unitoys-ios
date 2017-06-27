//
//  UNMessageModel.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/26.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseModel.h"

typedef enum {
    MJMessageTypeMe = 0, // 自己发的
    MJMessageTypeOther = 1,  // 别人发的
} MJMessageType;

typedef enum {
    MJMessageStatuProcessing = 0,   //正在处理
    MJMessageStatuSuccess = 1,      //处理成功
    MJMessageStatuError = 2       //处理失败
} MJMessageStatu;

@interface UNMessageModel : BaseModel

+ (UNMessageModel *)modelWithDict:(NSDictionary *)dict;

/**
 *  发送人
 */
@property (nonatomic, copy) NSString *Fm;
/**
 *  一个或多个（逗号连接）短信接收者号码
 */
@property (nonatomic, copy) NSString *To;
/**
 *  发送时间/接收时间
 */
@property (nonatomic, copy) NSString *SMSTime;
/**
 *  短信内容
 */
@property (nonatomic, copy) NSString *SMSContent;
/**
 *  1发送/0接收
 */
@property (nonatomic, assign) BOOL IsSend;
/**
 *  1已读/0未读
 */
@property (nonatomic, assign) BOOL IsRead;
/**
 *  短信ID
 */
@property (nonatomic, copy) NSString *SMSID;
/**
 *  0处理中(Int)/1处理成功(Success)/2处理失败(Error)
 */
@property (nonatomic, assign) MJMessageStatu Status;


/**
 *  信息的类型
 */
@property (nonatomic, assign) MJMessageType type;
//是否隐藏时间
@property (readwrite) BOOL hideTime;

@end
