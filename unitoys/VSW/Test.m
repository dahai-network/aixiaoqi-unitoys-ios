//
//  Test.m
//  unitoys
//
//  Created by 董杰 on 2017/1/14.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "Test.h"
#import <Foundation/Foundation.h>

void logSomething(char *senderStr)
{
//    UNDebugLogVerbose(@"传出来的数据 --- %s", senderStr);
    NSString *newString = [NSString stringWithFormat:@"%s", senderStr];
//    NSString *subStr = [newString substringFromIndex:8];
//    UNDebugLogVerbose(@"处理之后的数据 -- %@", subStr);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tcppacket" object:newString];
}

void sendICCIDValue(char *value) {
//    UNDebugLogVerbose(@"传出来的iccid和IMSI -- %s", value);
    
    NSString *valueStr = [NSString stringWithFormat:@"%s", value];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"iccidAndImsi" object:valueStr];
}

void sendTLVLength(int length) {
//    UNDebugLogVerbose(@"传过来的预读数据压缩前的长度 -- %d", length);
    NSString *lengthStr = [NSString stringWithFormat:@"%d", length];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"packetLength" object:lengthStr];
}

void receiveNewData(char *newData) {
    NSString *newDataStr = [NSString stringWithFormat:@"%s", newData];
    UNDebugLogVerbose(@"收到的需要发送的数据 -- %@", newDataStr);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveNewDataStr" object:newDataStr];
}

