//
//  SportDataCell.h
//  unitoys
//
//  Created by sumars on 16/11/24.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SportDataCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblSportTime; //运动时间
@property (weak, nonatomic) IBOutlet UILabel *stepNum;//运动步数
@property (weak, nonatomic) IBOutlet UILabel *distance;//距离
@property (weak, nonatomic) IBOutlet UILabel *consume;//消耗



@end
