//
//  UNPushKitMessageManager.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/25.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNPushKitMessageManager.h"

static UNPushKitMessageManager *manager = nil;
@implementation UNPushKitMessageManager

+ (UNPushKitMessageManager *)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[super allocWithZone:nil] init];
    });
    return manager;
}

- (NSMutableArray *)pushKitMsgQueue
{
    if (!_pushKitMsgQueue) {
        _pushKitMsgQueue = [NSMutableArray array];
    }
    return _pushKitMsgQueue;
}

- (NSArray *)sendICCIDCommands
{
    if (!_sendICCIDCommands) {
        _sendICCIDCommands = [NSArray array];
    }
    return _sendICCIDCommands;
}



@end
