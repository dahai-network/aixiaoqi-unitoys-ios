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


@property (weak, nonatomic) IBOutlet UILabel *lblContent2;
@property (weak, nonatomic) IBOutlet UIButton *firstButton2;
@property (weak, nonatomic) IBOutlet UIButton *secondButton2;
@property (weak, nonatomic) IBOutlet UIButton *threeButton2;
@property (weak, nonatomic) IBOutlet UIView *firstButtonView2;
@property (weak, nonatomic) IBOutlet UIView *secondButtonView2;
@property (weak, nonatomic) IBOutlet UIView *threeButtonView2;

@end
