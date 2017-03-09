//
//  UNGetSimData.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/7.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNGetSimData.h"


@implementation UNGetSimData

+ (UNSimCardAuthenticationModel *)getModelWithAuthenticationString:(NSString *)authenticationString
{
    if (authenticationString.length < 20) {
        return nil;
    }
    UNSimCardAuthenticationModel *model = [UNSimCardAuthenticationModel new];
    model.chn = [authenticationString substringWithRange:NSMakeRange(0, 2)];
    model.cmdIndex = [authenticationString substringWithRange:NSMakeRange(2, 2)];
    model.cmdLen = [authenticationString substringWithRange:NSMakeRange(4, 2)];
    model.paramLen = [authenticationString substringWithRange:NSMakeRange(6, 2)];
    model.expRspLen = [authenticationString substringWithRange:NSMakeRange(8, 6)];
    model.prefixNum = [authenticationString substringWithRange:NSMakeRange(14, 2)];
//    if ([model.prefixNum isEqualToString:@"00"] && [[authenticationString substringWithRange:NSMakeRange(16, 4)] isEqualToString:@"0000"]) {
//        //不进入目录
//        model.simData = [authenticationString substringFromIndex:20];
//        if ([[model.simData substringToIndex:4] isEqualToString:@"a088"]) {
//            model.isAddSendData = YES;
//        }
//        model.simTypePrefix = [model.simData substringToIndex:4];
//    }else{
        //有目录
        NSString *laterData = [authenticationString substringFromIndex:16];
        if (laterData.length) {
//            NSRange range = [laterData rangeOfString:@"0000"];
            //目录固定为12位
            NSRange range = NSMakeRange(12, 4);
            NSString *simDirectoryString = [laterData substringToIndex:range.location];
            NSInteger count = simDirectoryString.length/4;
            NSMutableArray *directoryArray = [NSMutableArray arrayWithCapacity:count];
            for (NSInteger i = 0; i < count; i++) {
                NSString *string = [simDirectoryString substringWithRange:NSMakeRange(i*4,4)];
                [directoryArray addObject:string];
            }
            model.simdirectory = directoryArray;
            
            NSString *simDataString = [laterData substringFromIndex:(range.location+range.length)];
            if ([[simDataString substringToIndex:4] isEqualToString:@"a088"]) {
                model.isAddSendData = YES;
            }
            model.simData = simDataString;
            model.simTypePrefix = [model.simData substringToIndex:4];
        }
//    }
    
    return model;
}

@end
