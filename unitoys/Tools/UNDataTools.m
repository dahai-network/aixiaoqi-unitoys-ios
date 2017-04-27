//
//  UNDataTools.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/14.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNDataTools.h"
#import "global.h"
#import "UNDatabaseTools.h"

@implementation UNDataTools

+ (UNDataTools *)sharedInstance
{
    static UNDataTools *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nil] init];
    });
    return instance;
}

- (NSMutableArray *)blackLists
{
    if (!_blackLists || !_blackLists.count) {
        _blackLists = [NSMutableArray arrayWithArray:[[UNDatabaseTools sharedFMDBTools] getBlackLists]];
    }
    return _blackLists;
}

- (NSString *)compareCurrentTimeStringWithRecord:(NSString *)compareDateString
{
    NSTimeInterval second = compareDateString.longLongValue;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    return [self compareCurrentTimeWithRecord:date];
}

-(NSString *)compareCurrentTimeWithRecord:(NSDate*) compareDate
{
    NSTimeInterval timeInterval = [compareDate timeIntervalSinceNow];
    timeInterval = -timeInterval;
    long temp = 0;
    NSString *result;
    if (timeInterval < 60) {
        result = INTERNATIONALSTRING(@"刚刚");
    }
    else if((temp = timeInterval/60) <60){
        result = [NSString stringWithFormat:@"%ld%@",temp, INTERNATIONALSTRING(@"分钟前")];
    }else{
        return [self compareCustomDate:compareDate];
    }
    return  result;
}

-(NSString *)compareCustomDate:(NSDate *)date{
    
    NSTimeInterval secondsPerDay = 24 * 60 * 60;
    NSDate *today = [[NSDate alloc] init];
    NSDate *yesterday, *beforeYesterday;
    //昨天
    yesterday = [today dateByAddingTimeInterval: -secondsPerDay];
    //前天
    beforeYesterday = [today dateByAddingTimeInterval:-secondsPerDay * 2];
    
    NSString * todayString = [[today description] substringToIndex:10];
    NSString * yesterdayString = [[yesterday description] substringToIndex:10];
    NSString * beforeYesterdayString = [[beforeYesterday description] substringToIndex:10];
    NSString * dateString = [[date description] substringToIndex:10];
    
    NSString *thisYear = [[today description] substringToIndex:4];
    NSString *dateYear = [[date description] substringToIndex:4];
    
    if ([dateString isEqualToString:todayString])
    {
        return [self getDayTimeString:date];
    } else if ([dateString isEqualToString:yesterdayString])
    {
        return [NSString stringWithFormat:@"%@ %@",INTERNATIONALSTRING(@"昨天"), [self getDayTimeString:date]];
    } else if ([dateString isEqualToString:beforeYesterdayString])
    {
        return [NSString stringWithFormat:@"%@ %@",INTERNATIONALSTRING(@"前天"), [self getDayTimeString:date]];
    }else if ([thisYear isEqualToString:dateYear]){
        return [self getDateTimeString:date IsThisYear:YES];
    }else
    {
        return [self getDateTimeString:date IsThisYear:NO];
    }
}

- (NSString *)getDayTimeString:(NSDate *)date
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"a HH:mm"];
    [formatter setAMSymbol:INTERNATIONALSTRING(@"上午")];
    [formatter setPMSymbol:INTERNATIONALSTRING(@"下午")];
    return [formatter stringFromDate:date];
}

- (NSString *)getDateTimeString:(NSDate *)date IsThisYear:(BOOL)isThisYear
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    if (isThisYear) {
        [formatter setDateFormat:@"MM-dd HH:mm"];
    }else{
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    }
    return [formatter stringFromDate:date];
}


@end
