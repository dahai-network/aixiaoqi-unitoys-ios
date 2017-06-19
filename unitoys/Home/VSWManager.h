//
//  VSWManager.h
//  unitoys
//
//  Created by 董杰 on 2017/1/13.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VSWManager : NSObject

@property (nonatomic, copy) NSString *vswIp;
@property (nonatomic, assign) int vswPort;
@property (nonatomic, copy) NSString *callPort;//电话端口

/**
 *  返回单例对象
 */
+(VSWManager *)shareManager;

- (void)simActionWithSimType:(NSString *)sender;

- (void)sendMessageToDev:(NSString *)length pdata:(NSString *)dataStr;

- (void)reconnectAction;

- (void)registAndInit;

@end
