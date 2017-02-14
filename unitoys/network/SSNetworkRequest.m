//
//  SSNetworkRequest.m
//  mobileclient
//
//  Created by ququ-iOS on 15/12/1.
//  Copyright © 2015年 ququ-iOS. All rights reserved.
//

#import "SSNetworkRequest.h"
#import "AFNetworking.h"
#import "BlueToothDataManager.h"

@implementation SSNetworkRequest

+ (void)getRequest:(NSString *)url params:(NSDictionary *)params success:(requestSuccessBlock)successHandler failure:(responseBlock)failureHandler headers:(NSDictionary *) headers{
    
    //网络不可用
    if (![self checkNetworkStatus]) {
        successHandler(nil);
        failureHandler(nil,nil);
        return;
    }
    
    AFHTTPSessionManager *manager = [self getRequstManager];
    //    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    
    //开始加载头部
    if (headers) {
        NSEnumerator *enumerator = [headers keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }
    
    /////////开始证书认证
    
//    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"https" ofType:@"cer"];
//    NSData * certData =[NSData dataWithContentsOfFile:cerPath];
//    //    NSSet * certSet = [[NSSet alloc] initWithObjects:certData, nil];
//    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
//    // 是否允许,NO-- 不允许无效的证书
//    [securityPolicy setAllowInvalidCertificates:YES];
//    // 设置证书
//    //    [securityPolicy setPinnedCertificates:@[certData]]; 2.0写法
//    [securityPolicy setPinnedCertificates:[[NSSet alloc] initWithObjects:certData, nil]];
//    
//    
//    //    [securityPolicy setPinnedCertificates:<#(NSArray * _Nullable)#>]
//    
//    manager.securityPolicy = securityPolicy;
    /////////结束证书认证
    [manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
        //
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //
        successHandler(responseObject);
        if (![BlueToothDataManager shareManager].isShowHud) {
            HUDStop;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //
        failureHandler(task.response,error);
        if (![BlueToothDataManager shareManager].isShowHud) {
            HUDStop;
        }
    }];
    
}


+ (void)postRequest:(NSString *)url params:(NSDictionary *)params success:(requestSuccessBlock)successHandler failure:(responseBlock)failureHandler headers:(NSDictionary *) headers{
    
    if (![self checkNetworkStatus]) {
        successHandler(nil);
        failureHandler(nil,nil);
        //        failureHandler(nil);
        return;
    }
    
    AFHTTPSessionManager *manager = [self getRequstManager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //开始加载头部
    if (headers) {
        NSEnumerator *enumerator = [headers keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }
    
    /////////开始证书认证
    
//    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"https" ofType:@"cer"];
//    NSData * certData =[NSData dataWithContentsOfFile:cerPath];
//    //    NSSet * certSet = [[NSSet alloc] initWithObjects:certData, nil];
//    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
//    // 是否允许,NO-- 不允许无效的证书
//    [securityPolicy setAllowInvalidCertificates:YES];
//    // 设置证书
//    [securityPolicy setPinnedCertificates:[[NSSet alloc] initWithObjects:certData, nil]];
//    //    [securityPolicy setPinnedCertificates:@[certData]];
//    //    [securityPolicy setPinnedCertificates:<#(NSArray * _Nullable)#>]
//    
//    manager.securityPolicy = securityPolicy;
    /////////结束证书认证
    
    
    [manager POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
        //
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //
        successHandler(responseObject);
        if (![BlueToothDataManager shareManager].isShowHud) {
            HUDStop;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //
        failureHandler(task.response,error);
        if (![BlueToothDataManager shareManager].isShowHud) {
            HUDStop;
        }
    }];
    /*
     [manager POST:url parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
     [1]	(null)	@"NSLocalizedDescription" : @"已取消"	
     successHandler(responseObject);
     } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
     //        XLLog(@"------请求失败-------%@",error);
     //        NSLog(@"有返回错误数据：%@",operation.responseObject);
     //        failureHandler(error);
     failureHandler(operation.responseObject,error);
     }];*/
}

/*
 + (void)postJsonRequest:(NSString *)url params:(NSDictionary *)params success:(requestSuccessBlock)successHandler failure:(responseBlock)failureHandler headers:(NSDictionary *) headers{
 
 if (![self checkNetworkStatus]) {
 successHandler(nil);
 failureHandler(nil,nil);
 //        failureHandler(nil);
 return;
 }
 
 AFHTTPSessionManager *manager = [self getRequstManager];
 
 //开始加载头部
 if (headers) {
 NSEnumerator *enumerator = [headers keyEnumerator];
 id key;
 while ((key = [enumerator nextObject])) {
 [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
 }
 }
 //                                 AFJSONRequestSerializerDing
 
 /////////开始证书认证
 
 NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"https" ofType:@"cer"];
 NSData * certData =[NSData dataWithContentsOfFile:cerPath];
 //    NSSet * certSet = [[NSSet alloc] initWithObjects:certData, nil];
 AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
 // 是否允许,NO-- 不允许无效的证书
 [securityPolicy setAllowInvalidCertificates:YES];
 // 设置证书
 [securityPolicy setPinnedCertificates:@[certData]];
 //    [securityPolicy setPinnedCertificates:<#(NSArray * _Nullable)#>]
 
 manager.securityPolicy = securityPolicy;
 /////////结束证书认证
 
 manager.requestSerializer = [AFJSONRequestSerializer serializer];
 
 [manager POST:url parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
 
 successHandler(responseObject);
 } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
 //        XLLog(@"------请求失败-------%@",error);
 //        NSLog(@"有返回错误数据：%@",operation.responseObject);
 //        failureHandler(error);
 failureHandler(operation.responseObject,error);
 }];
 } */

+ (void)putRequest:(NSString *)url params:(NSDictionary *)params success:(requestSuccessBlock)successHandler failure:(responseBlock)failureHandler headers:(NSDictionary *) headers {
    
    if (![self checkNetworkStatus]) {
        successHandler(nil);
        failureHandler(nil,nil);
        return;
    }
    
    AFHTTPSessionManager *manager = [self getRequstManager];
    
    //开始加载头部
    if (headers) {
        NSEnumerator *enumerator = [headers keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }
    
    /////////开始证书认证
    
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"https" ofType:@"cer"];
    NSData * certData =[NSData dataWithContentsOfFile:cerPath];
    //    NSSet * certSet = [[NSSet alloc] initWithObjects:certData, nil];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 是否允许,NO-- 不允许无效的证书
    [securityPolicy setAllowInvalidCertificates:YES];
    // 设置证书
    [securityPolicy setPinnedCertificates:[[NSSet alloc] initWithObjects:certData, nil]];
    //    [securityPolicy setPinnedCertificates:@[certData]];
    //    [securityPolicy setPinnedCertificates:<#(NSArray * _Nullable)#>]
    
    manager.securityPolicy = securityPolicy;
    /////////结束证书认证
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    [manager PUT:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        successHandler(responseObject);
        if (![BlueToothDataManager shareManager].isShowHud) {
            HUDStop;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureHandler(task.response,error);
        if (![BlueToothDataManager shareManager].isShowHud) {
            HUDStop;
        }
    }];
    /*
     [manager PUT:url parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
     
     successHandler(responseObject);
     } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
     //        XLLog(@"------请求失败-------%@",error);
     failureHandler(operation.responseObject,error);
     }];*/
}

+ (void)deleteRequest:(NSString *)url params:(NSDictionary *)params success:(requestSuccessBlock)successHandler failure:(requestFailureBlock)failureHandler {
    
    if (![self checkNetworkStatus]) {
        successHandler(nil);
        failureHandler(nil);
        return;
    }
    
    AFHTTPSessionManager *manager = [self getRequstManager];
    
    [manager DELETE:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        successHandler(responseObject);
        if (![BlueToothDataManager shareManager].isShowHud) {
            HUDStop;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureHandler(error);
        if (![BlueToothDataManager shareManager].isShowHud) {
            HUDStop;
        }
    }];
    /*
     [manager DELETE:url parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
     
     successHandler(responseObject);
     } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
     //        XLLog(@"------请求失败-------%@",error);
     failureHandler(error);
     }];*/
}




+ (AFHTTPSessionManager *)getRequstManager {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // 请求超时设定
    manager.requestSerializer.timeoutInterval = 20;
    //        manager.securityPolicy.allowInvalidCertificates = YES;
    
    return manager;
}


/**
 监控网络状态
 */
+ (BOOL)checkNetworkStatus {
    
    __block BOOL isNetworkUse = YES;
    
    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusUnknown) {
            isNetworkUse = YES;
        } else if (status == AFNetworkReachabilityStatusReachableViaWiFi){
            isNetworkUse = YES;
        } else if (status == AFNetworkReachabilityStatusReachableViaWWAN){
            isNetworkUse = YES;
        } else if (status == AFNetworkReachabilityStatusNotReachable){
            // 网络异常操作
            isNetworkUse = NO;
            //            XLLog(@"网络异常,请检查网络是否可用！");
        }
    }];
    [reachabilityManager startMonitoring];
    return isNetworkUse;
}

@end





/**
 *  用来封装上传文件数据的模型类
 */
@implementation SSFileConfig

+ (instancetype)fileConfigWithfileData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
    return [[self alloc] initWithfileData:fileData name:name fileName:fileName mimeType:mimeType];
}

- (instancetype)initWithfileData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
    if (self = [super init]) {
        
        _fileData = fileData;
        _name = name;
        _fileName = fileName;
        _mimeType = mimeType;
    }
    return self;
}

@end


