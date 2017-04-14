//
//  CallingViewController.h
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@class AddTouchAreaButton;
@interface CallingViewController : BaseViewController

- (IBAction)muteCalling:(id)sender;

- (IBAction)handfreeCalling:(id)sender;

- (IBAction)hungupCalling:(id)sender;

- (IBAction)callNumAction:(UIButton *)sender;

- (IBAction)hideKeyBoardAction:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UILabel *lblCallingHint;
@property (weak, nonatomic) IBOutlet UILabel *lblCallingInfo;

@property (weak, nonatomic) IBOutlet UIButton *btnMuteStatus;
@property (weak, nonatomic) IBOutlet UIButton *btnSpeakerStatus;
@property (weak, nonatomic) IBOutlet UIButton *callNumberStatus;
@property (weak, nonatomic) IBOutlet AddTouchAreaButton *hideKeyboardButton;

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (readwrite) BOOL callingStatus;

@property (readwrite) BOOL isMute;       //如果提早静音，要在接通后修改状态
@property (readwrite) BOOL isHandfree;   //如果提早免提，要在接通后修改状态
@property (readwrite) BOOL hadRing;      //是否已经振铃

@property (readwrite) int callSeconds;   //通话时间
@property (readwrite) NSTimer *callTimer;

@end
