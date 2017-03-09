//
//  UNSimCardAuthenticationModel.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/7.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UNSimCardAuthenticationModel : NSObject

@property (nonatomic, copy) NSString *chn;
@property (nonatomic, copy) NSString *cmdIndex;
@property (nonatomic, copy) NSString *cmdLen;
@property (nonatomic, copy) NSString *paramLen;
@property (nonatomic, copy) NSString *expRspLen;
@property (nonatomic, copy) NSString *prefixNum;
//目录
@property (nonatomic, copy) NSArray *simdirectory;
//数据
@property (nonatomic, copy) NSString *simData;

@property (nonatomic, copy) NSString *simTypePrefix;

//发送蓝牙指令数组
//@property (nonatomic, copy) NSArray *sendDataList;
@property (nonatomic, assign) BOOL isAddSendData;

@end
