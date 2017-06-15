//
//  SSNetworkRequest.h
//  mobileclient
//
//  Created by ququ-iOS on 15/12/1.
//  Copyright © 2015年 ququ-iOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@class AFHTTPSessionManager;

/**
 *  HUD隐藏
 *
 */
//#define HUDStop [MBProgressHUD hideAllHUDsForView:[[UIApplication sharedApplication].delegate window] animated:NO];

@class SSFileConfig;

/**
 请求成功block
 */
typedef void (^requestSuccessBlock)(id responseObj);

/**
 请求失败block
 */
typedef void (^requestFailureBlock) (NSError *error);

/**
 请求响应block
 */
typedef void (^responseBlock)(id dataObj, NSError *error);

/**
 进度block
 */
typedef void (^progressBlock)(NSProgress *progress);

/**
 监听进度响应block
 */
//typedef void (^progressBlock)(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);


@interface SSNetworkRequest : NSObject


+ (AFHTTPSessionManager *)getRequstManager;

/**
 GET请求
 */
+ (void)getRequest:(NSString *)url params:(id)params success:(requestSuccessBlock)successHandler failure:(responseBlock)failureHandler headers:(NSDictionary *) headers;

+ (void)getJsonRequest:(NSString *)url params:(id)params success:(requestSuccessBlock)successHandler failure:(responseBlock)failureHandler headers:(NSDictionary *) headers;
/**
 POST请求
 */
+ (void)postRequest:(NSString *)url params:(id)params success:(requestSuccessBlock)successHandler failure:(responseBlock)responseBlock headers:(NSDictionary *) headers;


/**
 上传文件

 @param url url
 @param params params
 @param datas 格式:@[@{@"data":@"",@"name":@""}]
 @param progress progress
 @param successHandler success
 @param responseBlock failed
 @param headers headers
 */
+ (void)updateDataRequest:(NSString *)url params:(id)params dataArray:(NSArray *)datas progress:(progressBlock)progress success:(requestSuccessBlock)successHandler failure:(responseBlock)responseBlock headers:(NSDictionary *) headers;

/**
 POST请求
 */
+ (void)postJsonRequest:(NSString *)url params:(NSDictionary *)params success:(requestSuccessBlock)successHandler failure:(responseBlock)responseBlock headers:(NSDictionary *) headers;

/**
 PUT请求
 */
+ (void)putRequest:(NSString *)url params:(NSDictionary *)params success:(requestSuccessBlock)successHandler failure:(responseBlock)failureHandler headers:(NSDictionary *) headers;

/**
 DELETE请求
 */
+ (void)deleteRequest:(NSString *)url params:(NSDictionary *)params success:(requestSuccessBlock)successHandler failure:(requestFailureBlock)failureHandler;

///**
// 下载文件，监听下载进度
// */
//+ (void)downloadRequest:(NSString *)url successAndProgress:(progressBlock)progressHandler complete:(responseBlock)completionHandler;
//
///**
// 文件上传
// */
//+ (void)updateRequest:(NSString *)url params:(NSDictionary *)params fileConfig:(SSFileConfig *)fileConfig success:(requestSuccessBlock)successHandler failure:(requestFailureBlock)failureHandler;
//
///**
// 文件上传，监听上传进度
// */
//+ (void)updateRequest:(NSString *)url params:(NSDictionary *)params fileConfig:(SSFileConfig *)fileConfig successAndProgress:(progressBlock)progressHandler complete:(responseBlock)completionHandler;

@end


/**
 *  用来封装上文件数据的模型类
 */
@interface SSFileConfig : NSObject
/**
 *  文件数据
 */
@property (nonatomic, strong) NSData *fileData;

/**
 *  服务器接收参数名
 */
@property (nonatomic, copy) NSString *name;

/**
 *  文件名
 */
@property (nonatomic, copy) NSString *fileName;

/**
 *  文件类型
 */
@property (nonatomic, copy) NSString *mimeType;

+ (instancetype)fileConfigWithfileData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

- (instancetype)initWithfileData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;
@end
