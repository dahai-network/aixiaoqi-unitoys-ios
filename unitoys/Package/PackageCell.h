//
//  PackageCell.h
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PackageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *lblPackageName;
@property (weak, nonatomic) IBOutlet UILabel *lblFlow;
@property (weak, nonatomic) IBOutlet UILabel *lblPrice;
@property (weak, nonatomic) IBOutlet UIImageView *imgOrder;


@end
