//
//  MJMessage.h
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MJMessageTypeMe = 0, // 自己发的
    MJMessageTypeOther   // 别人发的
} MJMessageType;

typedef enum {
    MJMessageStatuProcessing = 0,   //正在处理
    MJMessageStatuSuccess = 1,      //处理成功
    MJMessageStatuError = 2         //处理失败
} MJMessageStatu;

@interface MJMessage : NSObject

@property (nonatomic, copy) NSString *SMSID;
/**
 *  短信状态
 */
@property (nonatomic, assign) MJMessageStatu Status;
/**
 *  聊天内容
 */
@property (nonatomic, copy) NSString *text;
/**
 *  发送时间
 */
@property (nonatomic, copy) NSString *time;
/**
 *  信息的类型
 */
@property (nonatomic, assign) MJMessageType type;


@property (readwrite) BOOL hideTime;

+ (instancetype)messageWithDict:(NSDictionary *)dict;
- (instancetype)initWithDict:(NSDictionary *)dict;
@end
