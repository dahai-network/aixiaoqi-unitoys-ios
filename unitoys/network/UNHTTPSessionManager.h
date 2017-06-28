//
//  UNHTTPSessionManager.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/15.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@interface UNHTTPSessionManager : AFHTTPSessionManager

+ (UNHTTPSessionManager *)shareSessionManagerWithHeaders:(NSDictionary *)headers RequestType:(BOOL)isRequestJson;

@end
