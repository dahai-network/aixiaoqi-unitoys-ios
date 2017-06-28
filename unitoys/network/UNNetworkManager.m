//
//  UNNetworkManager.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/15.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNNetworkManager.h"
#import "UNHTTPSessionManager.h"
#import "UNDataTools.h"


@implementation UNNetworkManager

//+ (UNNetworkManager *)shareManager
//{
//    static UNNetworkManager *instance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        instance = [[super allocWithZone:nil] init];
//    });
//    return instance;
//}

+ (void)getUrl:(NSString *)urlString parameters:(id)parameters success:(void (^)(ResponseType, id _Nullable))success failure:(void (^)(NSError * _Nonnull))failure
{
    [[self getManager:urlString] GET:urlString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        ResponseType type;
        if ([[responseObject objectForKey:@"status"] intValue] == 1) {
            type = ResponseTypeSuccess;
        }else if ([[responseObject objectForKey:@"status"] intValue] == -999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            type = ResponseTypeRelogin;
        }else{
            type = ResponseTypeFailed;
        }
        if (success) {
            success(type, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

+ (void)getJsonUrl:(NSString *)urlString parameters:(id)parameters success:(void (^)(ResponseType, id _Nullable))success failure:(void (^)(NSError * _Nonnull))failure
{
    UNHTTPSessionManager *manager = [self getManager:urlString];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager GET:urlString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        ResponseType type;
        if ([[responseObject objectForKey:@"status"] intValue] == 1) {
            type = ResponseTypeSuccess;
        }else if ([[responseObject objectForKey:@"status"] intValue] == -999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            type = ResponseTypeRelogin;
        }else{
            type = ResponseTypeFailed;
        }
        if (success) {
            success(type, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}


+ (void)postUrl:(NSString *)urlString parameters:(id)parameters success:(void (^)(ResponseType,id _Nullable))success failure:(void (^)(NSError * _Nonnull))failure
{
    UNHTTPSessionManager *manager = [self getManager:urlString];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:urlString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        ResponseType type;
        if ([[responseObject objectForKey:@"status"] intValue] == 1) {
            type = ResponseTypeSuccess;
        }else if ([[responseObject objectForKey:@"status"] intValue] == -999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            type = ResponseTypeRelogin;
        }else{
            type = ResponseTypeFailed;
        }
        if (success) {
            success(type, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

+ (void)putUrl:(NSString *_Nonnull)urlString datas:(NSArray *_Nonnull)datas mimeType:(NSString *_Nullable)mimeType progress:(void (^_Nullable)(NSProgress *_Nullable))progress parameters:(id _Nullable)parameters success:(void (^_Nullable)(ResponseType responseType,id _Nullable responseObject))success failure:(void (^_Nullable)(NSError * _Nonnull error))failure
{
    if (!mimeType) {
        mimeType = @"application/octet-stream";
    }
    [[self getManager:urlString] POST:urlString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (int i=0; i<[datas count]; i++) {
            [formData appendPartWithFileData:[datas objectAtIndex:i][@"data"] name:[NSString stringWithFormat:@"file%d",i ] fileName:[datas objectAtIndex:i][@"name"] mimeType:mimeType];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
           progress(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        ResponseType type;
        if ([[responseObject objectForKey:@"status"] intValue] == 1) {
            type = ResponseTypeSuccess;
        }else if ([[responseObject objectForKey:@"status"] intValue] == -999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            type = ResponseTypeRelogin;
        }else{
            type = ResponseTypeFailed;
        }
        if (success) {
            success(type, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

+ (UNHTTPSessionManager *)getManager:(NSString *)urlString
{
    if (urlString) {
        if ([[UNDataTools sharedInstance].notokenUrls containsObject:urlString]) {
            return [UNHTTPSessionManager shareSessionManagerWithHeaders:[UNDataTools sharedInstance].notokenHeaders];
        }else{
            return [UNHTTPSessionManager shareSessionManagerWithHeaders:[UNDataTools sharedInstance].normalHeaders];
        }
    }else{
        return [UNHTTPSessionManager shareSessionManagerWithHeaders:[UNDataTools sharedInstance].normalHeaders];
    }
}

@end
