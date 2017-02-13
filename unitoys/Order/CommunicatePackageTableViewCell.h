//
//  CommunicatePackageTableViewCell.h
//  unitoys
//
//  Created by 董杰 on 2017/1/6.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommunicatePackageTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblPackageName;//套餐名字
@property (weak, nonatomic) IBOutlet UILabel *lblPackagePrice;//套餐价格
@property (weak, nonatomic) IBOutlet UILabel *lblValideDate;//有效期

@end
