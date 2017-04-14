//
//  CallComingInViewController.h
//  unitoys
//
//  Created by 董杰 on 2016/12/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@class AddTouchAreaButton;
@interface CallComingInViewController : BaseViewController
@property (nonatomic, copy) NSString *nameStr;

@property (nonatomic, assign) BOOL isPresentInCallKit;

@property (weak, nonatomic) IBOutlet UILabel *lbName;//电话号码栏
@property (weak, nonatomic) IBOutlet UILabel *lbTime;//通话时长栏

@property (weak, nonatomic) IBOutlet UIButton *btnMuteStatus;
@property (weak, nonatomic) IBOutlet UIButton *btnSpeakerStatus;

@property (weak, nonatomic) IBOutlet UIButton *callNumberStatus;
@property (weak, nonatomic) IBOutlet AddTouchAreaButton *hideKeyboardButton;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (readwrite) int callSeconds;   //通话时间
@property (readwrite) NSTimer *callTimer;


- (void)acceptCallFromCallKit;
- (void)setUpMuteButtonStatu:(BOOL)isMute;
- (void)setUpSpeakerButtonStatus:(BOOL)isSpeaker;
- (void)endCallPhone;
@end
