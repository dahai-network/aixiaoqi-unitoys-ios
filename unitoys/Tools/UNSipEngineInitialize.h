//
//  UNSipEngineInitialize.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UNSipEngineInitialize : NSObject

+ (UNSipEngineInitialize *)sharedInstance;

//初始化网络电话
- (void)initEngine;

@end
