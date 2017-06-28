//
//  UNNetworkManager.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/15.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ResponseType) {
    ResponseTypeSuccess = 0,
    ResponseTypeRelogin = 1,
    ResponseTypeFailed = 2,
};

@interface UNNetworkManager : NSObject

//+ (UNNetworkManager *_Nonnull)shareManager;

/**
 GET请求

 @param urlString url
 @param parameters parameters
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)getUrl:(NSString *_Nonnull)urlString parameters:(id _Nullable)parameters success:(void (^_Nullable)(ResponseType type,id _Nullable responseObj))success failure:(void (^_Nullable)(NSError * _Nonnull error))failure;


/**
 GETJson请求
 
 @param urlString url
 @param parameters parameters
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)getJsonUrl:(NSString *_Nonnull)urlString parameters:(id _Nullable)parameters success:(void (^_Nullable)(ResponseType type,id _Nullable responseObj))success failure:(void (^_Nullable)(NSError * _Nonnull error))failure;

/**
 POST请求
 
 @param urlString url
 @param parameters parameters
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)postUrl:(NSString *_Nonnull)urlString parameters:(id _Nullable)parameters success:(void (^_Nullable)(ResponseType type,id _Nullable responseObj))success failure:(void (^_Nullable)(NSError * _Nonnull error))failure;


/**
 PUT请求(上传数据)

 @param urlString url
 @param datas 需要上传的数据(格式:@[@{@"data":@"",@"name":@""}])
 @param mimeType 数据格式(@"image/jpeg",@"image/png",@"image/gif",@"image/tiff",@"application/pdf",@"application/vnd",@"text/plain",@"application/octet-stream")
 @param progress 上传进度
 @param parameters parameters
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)putUrl:(NSString *_Nonnull)urlString datas:(NSArray *_Nonnull)datas mimeType:(NSString *_Nullable)mimeType progress:(void (^_Nullable)(NSProgress *_Nullable progress))progress parameters:(id _Nullable)parameters success:(void (^_Nullable)(ResponseType type,id _Nullable responseObj))success failure:(void (^_Nullable)(NSError * _Nonnull error))failure;

@end
