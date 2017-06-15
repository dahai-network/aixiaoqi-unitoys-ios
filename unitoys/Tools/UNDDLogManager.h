//
//  UNDDLogManager.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/13.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

#define LOG_LEVEL_DEF ddLogLevel
#define LOG_ASYNC_ENABLED YES

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

//#define UNLogLBEProcess(format, ...) DDLogWarn((@"[Function:%s]" "[Line:%d]" format), __FUNCTION__, __LINE__, ##__VA_ARGS__);
#define UNLogLBEProcess(format, ...) DDLogWarn(format, ##__VA_ARGS__);
#define UNDebugLogVerbose(format, ...) DDLogVerbose((@"[%s][%d]" format), __FUNCTION__, __LINE__, ##__VA_ARGS__);

#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;

#define UNLogLBEProcess(format, ...) DDLogWarn(format, ##__VA_ARGS__);
#define UNDebugLogVerbose(format, ...) do{} while (0);

#endif

@interface UNDDLogManager : NSObject

+ (UNDDLogManager *)sharedInstance;

- (void)enabelUNLog;

//上传最后一个日志
- (void)updateLastLogToServer;
//上传所有日志
- (void)updateAllLogToServer;
//上传指定日志数量
- (void)updateLogToServerWithLogCount:(NSInteger)logCount;

@end
