//
//  PhoneRecordController.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

//#import "BaseTableController.h"
#import "BaseViewController.h"
#import "SipEngineUIDelegate.h"
#import "CallActionView.h"
#import "UCallPhonePadView.h"
#import "PhoneOperationPad.h"
//#import "UCallPhoneNumLabel.h"

typedef void(^IsHideTitleViewBlock)(BOOL isHidden);

@interface PhoneRecordController : BaseViewController<SipEngineUICallDelegate,SipEngineUIRegistrationDelegate>

@property (strong, nonatomic) UCallPhonePadView *phonePadView;

@property (strong, nonatomic) CallActionView *callActionView;


//@property (weak, nonatomic) UILabel *lblPhoneNumber;
@property (weak, nonatomic) UILabel *callTitleLabel;

@property (weak, nonatomic) PhoneOperationPad *callView;
@property (readwrite) NSString *phoneNumber;

@property (nonatomic, weak) UINavigationController *nav;

@property (strong,nonatomic) NSMutableArray *arrPhoneRecord;

@property (readwrite) BOOL speakerStatus;

@property (readwrite) BOOL muteStatus;

@property (readwrite) NSDate *callStartTime;

@property (readwrite) NSDate *callStopTime;

@property (readwrite) NSString * hostHungup; //主动挂断 source,dest

@property (readwrite) NSString *outIP;

@property (readwrite) NSString *calledTelNum;


@property (readwrite) int maxPhoneCall;

@property (nonatomic, copy) IsHideTitleViewBlock isHideTitleViewBlock;

- (BOOL)initEngine;

- (void)unregister;

@end

