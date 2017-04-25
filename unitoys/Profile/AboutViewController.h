//
//  AboutViewController.h
//  unitoys
//
//  Created by sumars on 16/9/20.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"

@interface AboutViewController : BaseTableController
@property (weak, nonatomic) IBOutlet UIImageView *ivUserHead;
@property (weak, nonatomic) IBOutlet UILabel *lblNickName;
@property (weak, nonatomic) IBOutlet UILabel *lblPhoneNumber;
@property (weak, nonatomic) IBOutlet UILabel *lblAmount;
@property (weak, nonatomic) IBOutlet UIView *havePackageView;
@property (weak, nonatomic) IBOutlet UIView *connectedDeviceView;

//有套餐可激活label
@property (weak, nonatomic) IBOutlet UILabel *haspackageTipMsgLabel;
//有新版本
@property (weak, nonatomic) IBOutlet UILabel *hasNewVersionLabel;

- (IBAction)accountRecharge:(id)sender;

- (IBAction)editProfile:(id)sender;

@end
