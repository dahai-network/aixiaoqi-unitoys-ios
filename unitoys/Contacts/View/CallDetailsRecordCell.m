//
//  CallDetailsRecordCell.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CallDetailsRecordCell.h"

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
    NSTimeInterval  timeInterval = [compareDate timeIntervalSinceNow];
    timeInterval = -timeInterval;
    long temp = 0;
    NSString *result;
    if (timeInterval < 60) {
        result = [NSString stringWithFormat:@"刚刚"];
    }
    else if((temp = timeInterval/60) <60){
        result = [NSString stringWithFormat:@"%ld分前",temp];
    }
    
    else if((temp = temp/60) <24){
        result = [NSString stringWithFormat:@"%ld小时前",temp];
    }
    
    else if((temp = temp/24) <30){
        result = [NSString stringWithFormat:@"%ld天前",temp];
    }
    
    else{
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        formatter.timeZone = [NSTimeZone localTimeZone];
        
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDateFormat:@"yyyy/MM/dd"];
        
        result = [formatter stringFromDate:compareDate];
        //直接输出时间
    }
    /* if((temp = temp/30) <12){
     result = [NSString stringWithFormat:@"%ld月前",temp];
     }
     else{
     temp = temp/12;
     result = [NSString stringWithFormat:@"%ld年前",temp];
     }*/
    
    return  result;
}

@end
