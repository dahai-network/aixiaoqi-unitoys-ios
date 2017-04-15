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

@end
