//
//  UNCreatLocalNoti.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UNCreatLocalNoti : NSObject

+ (void)createLocalNotiMessage:(NSDictionary *)dict;

+ (void)createLocalNotiMessageString:(NSString *)string;

@end
