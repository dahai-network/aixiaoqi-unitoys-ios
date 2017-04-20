//
//  CommunicateDetailTableViewCell.h
//  unitoys
//
//  Created by 董杰 on 2017/1/6.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommunicateDetailTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgCommunicatePhoto;
@property (weak, nonatomic) IBOutlet UILabel *lblCommunicateName;
@property (weak, nonatomic) IBOutlet UILabel *lblCommunicatePrice;
@property (weak, nonatomic) IBOutlet UILabel *lblFirstName;
@property (weak, nonatomic) IBOutlet UILabel *lblContent;
@property (weak, nonatomic) IBOutlet UIButton *firstButton;
@property (weak, nonatomic) IBOutlet UIButton *secondButton;
@property (weak, nonatomic) IBOutlet UIView *firstButtonView;
@property (weak, nonatomic) IBOutlet UIView *secondButtonView;
@property (weak, nonatomic) IBOutlet UILabel *lblValidity;
@property (weak, nonatomic) IBOutlet UIButton *buyButton;

@end
