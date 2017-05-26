//
//  UNSipEngineInitialize.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    SipRegisterStatuNone = 0,       //默认状态,未注册
    SipRegisterStatuProgress = 1,   //正在注册
    SipRegisterStatuSuccess = 2,    //注册成功
    SipRegisterStatuCleared = 3,    //账号注销
    SipRegisterStatuFailed = 4,     //注册失败
} SipRegisterStatu;

typedef enum : NSUInteger {
    SipCallPhoneStatuNone = 0,              //默认状态,未通话
    SipCallPhoneStatuNewCall = 1,           //新呼叫
    SipCallPhoneStatuCallProcessing = 2,    //正在呼叫
    SipCallPhoneStatuCallRinging = 3,       //对方振铃
    SipCallPhoneStatuCallConnected = 4,     //通话接通
    SipCallPhoneStatuCallStreamsRunning = 5,//正在通话
    SipCallPhoneStatuCallEnded = 6,         //通话结束
    SipCallPhoneStatuCallFailed = 7,        //呼叫失败
} SipCallPhoneStatu;

@interface UNSipEngineInitialize : NSObject


+ (UNSipEngineInitialize *)sharedInstance;

//初始化网络电话
- (void)initEngine;

//sip注册状态
@property (nonatomic, assign) SipRegisterStatu sipRegisterStatu;
//sip通话状态
@property (nonatomic, assign) SipCallPhoneStatu sipCallPhoneStatu;

@end
