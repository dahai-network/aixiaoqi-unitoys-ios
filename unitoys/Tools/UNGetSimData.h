//
//  UNGetSimData.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/7.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UNSimCardAuthenticationModel.h"

@interface UNGetSimData : NSObject

//解析鉴权数据
+ (UNSimCardAuthenticationModel *)getModelWithAuthenticationString:(NSString *)authenticationString;

@end
