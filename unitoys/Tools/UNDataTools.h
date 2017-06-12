//
//  UNDataTools.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/14.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UNDataTools : NSObject

+ (UNDataTools *)sharedInstance;

- (NSString *)compareCurrentTimeStringWithRecord:(NSString *)compareDateString;

//黑名单列表
@property (nonatomic, strong) NSMutableArray *blackLists;

//是否去国外
@property (nonatomic, assign) BOOL isGoAbroad;

//去国外当前境外说明步数
@property (nonatomic, assign) NSInteger goAbroadCurrentAbroadStep;
//去国外总步数
@property (nonatomic, assign) NSInteger goAbroadTotalStep;


//回国后当前境外说明步数
@property (nonatomic, assign) NSInteger goHomeCurrentAbroadStep;
//回国后总步数
@property (nonatomic, assign) NSInteger goHomeTotalStep;

//教程数据
@property (nonatomic, copy) NSArray *pagesData;

//是否有商城消息
@property (nonatomic, assign) BOOL isHasMallMessage;
//是否有未激活提示
@property (nonatomic, assign) BOOL isHasNotActiveTip;
//是否有固件升级提示
@property (nonatomic, assign) BOOL isHasFirmwareUpdateTip;
//是否已弹出验证界面
@property (nonatomic, assign) BOOL isShowVerificationVc;

//是否有未接来电
@property (nonatomic, assign) BOOL isHasMissCall;
//是否有未读短信
@property (nonatomic, assign) BOOL isHasUnreadSMS;
//当前未读短信号码数组
@property (nonatomic, strong) NSMutableArray *currentUnreadSMSPhones;

@property (nonatomic, copy) NSDictionary *normalHeaders;

@property (nonatomic, assign) CGFloat tipStatusHeight;
@property (nonatomic, assign) CGFloat pageViewHeight;

+ (BOOL)isSaveTodayDateWithKey:(NSString *)key TodayString:(void(^)(NSString *todayStr))block;

@end
