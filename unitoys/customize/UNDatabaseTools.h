//
//  UNDatabaseTools.h
//  unitoys
//
//  Created by 黄磊 on 2017/3/1.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

@interface UNDatabaseTools : NSObject

+ (instancetype)sharedFMDBTools;

- (BOOL)insertDataWithAPIName:(NSString *)apiName dictData:(NSDictionary *)response;
//- (BOOL)insertDataWithAPIName:(NSString *)apiName jsonData:(NSString *)jsonString;
- (BOOL)deleteTableWithAPIName:(NSString *)apiName;

- (NSDictionary *)getResponseWithAPIName:(NSString *)apiName;

@end
