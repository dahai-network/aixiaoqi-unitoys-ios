//
//  OpenServiceMonthCell.h
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^SelectIndexBlock)(NSInteger selectIndex);
@interface OpenServiceMonthCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *selectMonthButtons;
@property (nonatomic, copy) SelectIndexBlock selectIndexBlock;

- (void)updateCellWithDatas:(NSDictionary *)dict appendText:(NSString *)appendString selectIndex:(NSInteger)selectIndex;

//width : kwidth - 30
@property (weak, nonatomic) IBOutlet UIView *monthContentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *monthContentViewHeight;

@end
