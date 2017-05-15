//
//  OpenServiceMonthCell.h
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^SelectMonthBlock)(NSInteger selectMonth);
@interface OpenServiceMonthCell : UITableViewCell

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *selectMonthButtons;
@property (nonatomic, copy) SelectMonthBlock selectMonthBlock;

- (void)updateCellWithDatas:(NSDictionary *)dict;

//width : kwidth - 30
@property (weak, nonatomic) IBOutlet UIView *monthContentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *monthContentViewHeight;

@end
