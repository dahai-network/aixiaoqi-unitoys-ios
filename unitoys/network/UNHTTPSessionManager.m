//
//  UNHTTPSessionManager.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/15.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNHTTPSessionManager.h"

@implementation UNHTTPSessionManager

+ (UNHTTPSessionManager *)shareSessionManagerWithHeaders:(NSDictionary *)headers RequestType:(BOOL)isRequestJson
{
    UNHTTPSessionManager *manager = [self manager];
    if (isRequestJson) {
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    manager.requestSerializer.timeoutInterval = 20;
    if (headers) {
        NSEnumerator *enumerator = [headers keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }
    return manager;
}


@end
