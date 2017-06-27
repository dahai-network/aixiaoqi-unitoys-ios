//
//  VSWManager.m
//  unitoys
//
//  Created by 董杰 on 2017/1/13.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "VSWManager.h"
#include "eos_typedef.h"
#include "sim_com_interface.h"
#include "sim_com_app.h"
#include "sim_com_preread.h"

static VSWManager * manager=nil;

@interface VSWManager ()
@property (nonatomic, assign)BOOL isNeedReSetSDK;

@end

@implementation VSWManager

+ (VSWManager *)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)simActionWithSimType:(NSString *)sender {
    if (!self.isNeedReSetSDK) {
        self.isNeedReSetSDK = YES;
        SimComInit();
        ST_SIMCOM_APPEVT appEvtSendBuff;
        appEvtSendBuff.chn = 0;
        appEvtSendBuff.evtIndex = EN_APPEVT_SETSIMTYPE;
        appEvtSendBuff.len = 1;
        int endMinutes = [sender intValue];
        Byte endMinuteByte = (Byte)0xff&endMinutes;
        appEvtSendBuff.pData = &endMinuteByte;
        UNDebugLogVerbose(@"前面传入的结构体参数 -- %hhu", endMinuteByte);
        SimComEvtApp2Drv(&appEvtSendBuff);
        SimCom_Task();
    } else {
        [self registAndInit];
    }
}

- (void)sendMessageToDev:(NSString *)length pdata:(NSString *)dataStr {
    ST_SIMCOM_APPEVT appEvtSendBuff;
    appEvtSendBuff.chn = 0;
    appEvtSendBuff.evtIndex = EN_APPEVT_SIMDATA;
    appEvtSendBuff.len = [length intValue];
    Byte bytes = (Byte)[[self convertHexStrToData:dataStr] bytes];
    
    appEvtSendBuff.pData = [[self convertHexStrToData:dataStr] bytes];//传value
    UNLogLBEProcess(@"发送给服务器的数据 -- %@", [self convertHexStrToData:dataStr]);
    SimComEvtApp2Drv(&appEvtSendBuff);
}

- (void)reconnectAction {
    UNDebugLogVerbose(@"走了不从0开始注册初始化VSW的步骤");
    ST_SIMCOM_APPEVT appEvtSendBuff;
    appEvtSendBuff.chn = 0;
    appEvtSendBuff.evtIndex = EN_APPEVT_CMD_SIMCLR;
    appEvtSendBuff.len = 1;
    int endMinutes = 1;
    Byte endMinuteByte = (Byte)0xff&endMinutes;
    appEvtSendBuff.pData = &endMinuteByte;
    SimComEvtApp2Drv(&appEvtSendBuff);
}


- (void)registAndInit {
    UNDebugLogVerbose(@"走了重新初始化VSW的步骤");
    ST_SIMCOM_APPEVT appEvtSendBuff;
    appEvtSendBuff.chn = 0;
    appEvtSendBuff.evtIndex = EN_APPEVT_CMD_SETRST;
    appEvtSendBuff.len = 1;
    int endMinutes = 1;
    Byte endMinuteByte = (Byte)0xff&endMinutes;
    appEvtSendBuff.pData = &endMinuteByte;
    SimComEvtApp2Drv(&appEvtSendBuff);
}

- (NSData *)convertHexStrToData:(NSString *)str {
    if (!str || [str length] == 0) {
        return nil;
    }
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}

@end
