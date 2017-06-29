//
//  UNNetWorkStatuManager.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/28.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

typedef void(^NetWorkStatuChangeBlock)(NetworkStatus currentStatu);

@interface UNNetWorkStatuManager : NSObject

+ (UNNetWorkStatuManager *)shareManager;
- (void)initNetWorkStatuManager;
//
////是否初始化过
@property (nonatomic, readonly) BOOL isInitInstance;
////当前网络状态
@property (nonatomic, readonly) NetworkStatus currentStatu;

@property (nonatomic, copy) NetWorkStatuChangeBlock netWorkStatuChangeBlock;

@end
