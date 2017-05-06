//
//  UNNetWorkStatuManager.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/28.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNNetWorkStatuManager.h"


@interface UNNetWorkStatuManager()

@property (nonatomic, assign) BOOL isInitInstance;
@property (nonatomic, assign) NetworkStatus currentStatu;

@end

static UNNetWorkStatuManager *manager = nil;

@implementation UNNetWorkStatuManager

+ (UNNetWorkStatuManager *)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[super allocWithZone:nil] init];
    });
    return manager;
}

- (void)initNetWorkStatuManager
{
    if (self.isInitInstance) {
        return;
    }
    self.isInitInstance = YES;
    Reachability *reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    [reach startNotifier];
    self.currentStatu = [reach currentReachabilityStatus];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityStatuChange:) name:kReachabilityChangedNotification object:nil];
        self.currentStatu = [reach currentReachabilityStatus];
    });
}

- (void)reachabilityStatuChange:(NSNotification *)noti
{
    if (![noti.object isKindOfClass:[Reachability class]]) {
        return;
    }
    Reachability *reach = noti.object;
    NetworkStatus netStatu = [reach currentReachabilityStatus];
    if (self.currentStatu != netStatu) {
        self.currentStatu = netStatu;
        if (_netWorkStatuChangeBlock) {
            _netWorkStatuChangeBlock(netStatu);
        }
    }

}

@end
