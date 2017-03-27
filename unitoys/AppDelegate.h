//
//  AppDelegate.h
//  unitoys
//
//  Created by sumars on 16/9/11.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WXApi.h"
#import <Bugly/Bugly.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,WXApiDelegate, BuglyDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, assign) int currentNumber;//记录心跳包次数，从08开始

//@property (nonatomic, readonly) BOOL isPushKit;
//@property (nonatomic, assign) BOOL isNeedRegister;
//@property (nonatomic, copy) NSDictionary *simDataDict;
//
//@property (nonatomic, readonly) PushKitMessageType pushKitMsgType;
//
//
//@property (nonatomic, assign) BOOL isAppAlreadyLoad;//APP是否已加载(是否加载过HomeVC)
@end

