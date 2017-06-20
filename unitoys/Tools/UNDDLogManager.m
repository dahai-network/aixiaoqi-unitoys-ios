//
//  UNDDLogManager.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/13.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNDDLogManager.h"
#import "SSNetworkRequest.h"
#import "UNDataTools.h"
#import "MBProgressHUD+UNTip.h"

//NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//NSString *baseDir = paths.firstObject;
//NSString *logsDirectory = [baseDir stringByAppendingPathComponent:@"UNLogs"];

@interface UNDDLogManager()

@property (nonatomic, copy) NSString *defaultFilePath;
@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, weak) DDFileLogger *fileLog;

@end


@implementation UNDDLogManager

- (NSString *)defaultFilePath
{
    if (!_defaultFilePath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *baseDir = paths.firstObject;
        _defaultFilePath = [baseDir stringByAppendingPathComponent:@"UNLogs"];
    }
    return _defaultFilePath;
}

+ (UNDDLogManager *)sharedInstance
{
    static UNDDLogManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nil] init];
    });
    return instance;
}

- (NSFileManager *)fileManager
{
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

- (void)enabelUNLog
{
#ifdef DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDFileLogger *fileLog = [[DDFileLogger alloc] init];
    _fileLog = fileLog;
    fileLog.rollingFrequency = 60 * 60 * 12;
    fileLog.logFileManager.maximumNumberOfLogFiles = 5;
    [DDLog addLogger:fileLog];
#else
    DDFileLogger *fileLog = [[DDFileLogger alloc] init];
    _fileLog = fileLog;
    //    fileLog.rollingFrequency = 60 * 60 * 24;
    //    fileLog.logFileManager.maximumNumberOfLogFiles = 2;
    fileLog.rollingFrequency = 60 * 60 * 12;
    fileLog.logFileManager.maximumNumberOfLogFiles = 3;
    [DDLog addLogger:fileLog];
#endif
}

//上传最后一个日志
- (void)updateLastLogToServer
{
    [self updateLogToServerWithLogCount:1];
}
//上传所有日志
- (void)updateAllLogToServer
{
    [self updateLogToServerWithLogCount:0];
}
//上传指定日志数量
- (void)updateLogToServerWithLogCount:(NSInteger)logCount
{
    if ([self.fileManager fileExistsAtPath:self.defaultFilePath]) {
        NSArray *fileList = [self.fileLog.logFileManager sortedLogFileNames];
//        NSArray *logpathArray = [self.fileLog.logFileManager sortedLogFilePaths];
//        NSArray *fileList = [self.fileManager contentsOfDirectoryAtPath:self.defaultFilePath error:nil];
        UNDebugLogVerbose(@"文件列表====%@",fileList);
        NSInteger updateCount;
        if (fileList.count) {
            if (logCount == 0 || logCount > fileList.count) {
                updateCount = fileList.count;
            }else{
                updateCount = logCount;
            }
            if (updateCount) {
                NSArray *datas = [self getFileDataWithCount:updateCount WithFileList:fileList];
//                UNLogLBEProcess(@"需要上传的数据datas==%@", datas);
                [self updateImageDataArray:datas];
            }
        }
    }else{
        UNDebugLogVerbose(@"不存在目录");
    }
}

- (NSArray *)getFileDataWithCount:(NSInteger)logCount WithFileList:(NSArray *)lists
{
    NSMutableArray *dataArray = [NSMutableArray array];
//    NSArray *pathNames = [[lists reverseObjectEnumerator] allObjects];
    NSArray *pathNames = [lists subarrayWithRange:NSMakeRange(0, logCount)];
    for (NSString *path in pathNames) {
        UNLogLBEProcess(@"Path====%@", path);
        NSData *data = [self.fileManager contentsAtPath:[self.defaultFilePath stringByAppendingFormat:@"/%@", path]];
        if (data) {
            [dataArray addObject:@{@"name" : path, @"data" : data}];
        }
    }
    return dataArray;
}

- (void)updateImageDataArray:(NSArray *)dataArray
{
////    [MBProgressHUD showLoadingWithMessage:@"正在上传"];
//    [SSNetworkRequest updateDataRequest:apiUploadUserLog params:nil dataArray:dataArray progress:^(NSProgress *progress) {
////        [MBProgressHUD showLoadingWithProgress:progress.fractionCompleted ProgressType:UNProgressTypeAnnularDeterminate];
//        UNDebugLogVerbose(@"progress===%.2f", progress.fractionCompleted)
//    } success:^(id responseObj) {
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            UNDebugLogVerbose(@"%@", responseObj)
////            [MBProgressHUD showSuccess:@"上传成功"];
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
////            [MBProgressHUD showSuccess:@"上传失败"];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }else{
////            [MBProgressHUD showError:responseObj[@"msg"]];
//        }
//    } failure:^(id dataObj, NSError *error) {
////        [MBProgressHUD showSuccess:@"上传失败"];
//    } headers:[UNDataTools sharedInstance].normalHeaders];
    
    [UNNetworkManager putUrl:apiUploadUserLog datas:dataArray mimeType:nil progress:^(NSProgress * _Nullable progress) {
//        UNDebugLogVerbose(@"progress===%.2f", progress.fractionCompleted)
    } parameters:nil success:^(ResponseType type, id  _Nullable responseObj) {
        if (type == ResponseTypeSuccess) {
            UNDebugLogVerbose(@"%@", responseObj)
        }else if (type == ResponseTypeFailed){
            UNDebugLogVerbose(@"%@", responseObj)
        }
    } failure:^(NSError * _Nonnull error) {
        
    }];
}


- (void)clearAllLog
{
    if ([self.fileManager fileExistsAtPath:self.defaultFilePath]) {
        NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:self.defaultFilePath];
        NSString *fileName;
        while (fileName = [dirEnum nextObject]) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",self.defaultFilePath,fileName] error:&error];
            if (error) {
                UNLogLBEProcess(@"删除日志失败===%@", error);
            }
        }
        UNLogLBEProcess(@"删除日志完成");
    }else{
        UNLogLBEProcess(@"不存在目录");
    }

}

//获取日志数据
- (NSArray *)getAllLogLists
{
    NSArray *fileList = [self.fileLog.logFileManager sortedLogFileNames];
    NSArray *datas = [self getFileDataWithCount:fileList.count WithFileList:fileList];
    return datas;
}

@end
