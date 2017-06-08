//
//  CallDetailsRecordCell.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CallDetailsRecordCell.h"
#import "global.h"
#import "UNDataTools.h"
#import "UNConvertFormatTool.h"

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
        self.iconImageView.hidden = NO;
        self.timelabel.textColor = UIColorFromRGB(0x333333);
        self.iconImageView.image = [UIImage imageNamed:@"to_phone"];
    }else{
        if ([cellDatas[@"status"] intValue] == 0) {
            self.iconImageView.hidden = YES;
            self.timelabel.textColor = [UIColor redColor];
        }else{
            self.iconImageView.hidden = NO;
            self.timelabel.textColor = UIColorFromRGB(0x333333);
            self.iconImageView.image = [UIImage imageNamed:@"from_phone"];
        }
    }
    
    NSString *callduration = @"00:00";
    if (cellDatas[@"callduration"]) {
        callduration = [UNConvertFormatTool minSecWithSeconds:[cellDatas[@"callduration"] intValue]];
    }
    self.callDuration.text = callduration;
    self.timelabel.text = [[UNDataTools sharedInstance] compareCurrentTimeStringWithRecord:cellDatas[@"calltime"]];
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
