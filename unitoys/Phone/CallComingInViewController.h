//
//  CallComingInViewController.h
//  unitoys
//
//  Created by 董杰 on 2016/12/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface CallComingInViewController : BaseViewController
@property (nonatomic, copy) NSString *nameStr;
@property (weak, nonatomic) IBOutlet UILabel *lbName;//电话号码栏
@property (weak, nonatomic) IBOutlet UILabel *lbTime;//通话时长栏

@property (weak, nonatomic) IBOutlet UIButton *btnMuteStatus;
@property (weak, nonatomic) IBOutlet UIButton *btnSpeakerStatus;

@property (readwrite) int callSeconds;   //通话时间
@property (readwrite) NSTimer *callTimer;

@end
