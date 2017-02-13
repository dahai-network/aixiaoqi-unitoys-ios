//
//  ActivateGiftCardTableViewCell.h
//  unitoys
//
//  Created by 董杰 on 2017/1/4.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivateGiftCardTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgOrderView;//图片
@property (weak, nonatomic) IBOutlet UILabel *lblOrderName;//套餐名称
@property (weak, nonatomic) IBOutlet UILabel *lblOrderPrice;//套餐价格
@property (weak, nonatomic) IBOutlet UILabel *lblContentName;//栏目名称
@property (weak, nonatomic) IBOutlet UILabel *lblContent;//栏目内容
@property (weak, nonatomic) IBOutlet UILabel *lblIntroduceFirst;//上面介绍
@property (weak, nonatomic) IBOutlet UILabel *lblIntroduceSecond;//下面介绍


@end
