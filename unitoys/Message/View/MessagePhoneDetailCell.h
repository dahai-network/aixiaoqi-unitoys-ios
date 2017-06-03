//
//  MessagePhoneDetailCell.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/28.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessagePhoneDetailCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIButton *callButton;

@end
