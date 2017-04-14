//
//  CallDetailsRecordCell.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CallDetailsRecordCell.h"
#import "global.h"

@implementation CallDetailsRecordCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

- (void)setCellDatas:(NSDictionary *)cellDatas
{
    _cellDatas = cellDatas;
    if ([cellDatas[@"calltype"] isEqualToString:@"去电"]) {
        self.iconImageView.image = [UIImage imageNamed:@"to_phone"];
    }else{
        self.iconImageView.image = [UIImage imageNamed:@"from_phone"];
    }
    self.timelabel.text = [self compareCurrentTimeString:cellDatas[@"calltime"]];
}

- (NSString *)compareCurrentTimeString:(NSString *)compareDateString
{
    NSTimeInterval second = compareDateString.longLongValue;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    return [self compareCurrentTime:date];
}

-(NSString *) compareCurrentTime:(NSDate*) compareDate
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
    
    if ([dateString isEqualToString:todayString])
    {
        return [self getDayTimeString:date];
    } else if ([dateString isEqualToString:yesterdayString])
    {
        return [NSString stringWithFormat:@"%@ %@",INTERNATIONALSTRING(@"昨天"), [self getDayTimeString:date]];
    } else if ([dateString isEqualToString:beforeYesterdayString])
    {
        return [NSString stringWithFormat:@"%@ %@",INTERNATIONALSTRING(@"前天"), [self getDayTimeString:date]];
    }
    else
    {
        return [self getDateTimeString:date];
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

- (NSString *)getDateTimeString:(NSDate *)date
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    return [formatter stringFromDate:date];
}


//-(NSString *) compareCurrentTime:(NSDate*) compareDate
//{
//    NSTimeInterval  timeInterval = [compareDate timeIntervalSinceNow];
//    timeInterval = -timeInterval;
//    long temp = 0;
//    NSString *result;
//    if (timeInterval < 60) {
//        result = [NSString stringWithFormat:@"刚刚"];
//    }
//    else if((temp = timeInterval/60) <60){
//        result = [NSString stringWithFormat:@"%ld分前",temp];
//    }
//    
//    else if((temp = temp/60) <24){
//        result = [NSString stringWithFormat:@"%ld小时前",temp];
//    }
//    
//    else if((temp = temp/24) <30){
//        result = [NSString stringWithFormat:@"%ld天前",temp];
//    }
//    
//    else{
//        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
//        formatter.timeZone = [NSTimeZone localTimeZone];
//        
//        [formatter setDateStyle:NSDateFormatterMediumStyle];
//        [formatter setTimeStyle:NSDateFormatterShortStyle];
//        [formatter setDateFormat:@"yyyy/MM/dd"];
//        
//        result = [formatter stringFromDate:compareDate];
//        //直接输出时间
//    }
//    return  result;
//}

@end
