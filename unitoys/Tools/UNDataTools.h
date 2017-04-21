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

//当前境外说明步数
@property (nonatomic, assign) NSInteger currentAbroadStep;
//总步数
@property (nonatomic, assign) NSInteger totalStep;
//教程数据
@property (nonatomic, copy) NSArray *pagesData;

//是否有商城消息
@property (nonatomic, assign) BOOL isHasMallMessage;
//是否有未激活提示
@property (nonatomic, assign) BOOL isHasNotActiveTip;
//是否有固件升级提示
@property (nonatomic, assign) BOOL isHasFirmwareUpdateTip;

@end
