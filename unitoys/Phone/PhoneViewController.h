//
//  PhoneViewController.h
//  unitoys
//
//  Created by sumars on 16/10/25.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"
#import "PhonePadView.h"
#import "CallActionView.h"

#import "PhoneOperationPad.h"

#import "SipEngineUIDelegate.h"
//btn_call_key.png
@interface PhoneViewController : BaseViewController<SipEngineUICallDelegate,SipEngineUIRegistrationDelegate,UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate>


@property (weak, nonatomic) IBOutlet UIButton *btnWriteMessage;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet PhonePadView *phonePadView;

@property (strong, nonatomic) CallActionView *callActionView;

@property (readwrite) NSInteger phoneOperation;

@property (strong,nonatomic) NSMutableArray *arrPhoneRecord;
@property (strong,nonatomic) NSArray *arrMessageRecord;

@property (weak, nonatomic) UILabel *lblPhoneNumber;

@property (weak, nonatomic) PhoneOperationPad *callView;

@property (readwrite) NSString *phoneNumber;

@property (readwrite) int maxPhoneCall;

@property (readwrite) NSDate *callStartTime;

@property (readwrite) NSDate *callStopTime;

@property (readwrite) NSString * hostHungup; //主动挂断 source,dest

@property (readwrite) NSString *outIP;

@property (readwrite) NSString *calledTelNum;

@property (readwrite) BOOL speakerStatus;

@property (readwrite) BOOL muteStatus;

@property (readwrite) BOOL numberPadStatus; //记录拨号盘状态

@property (nonatomic, assign) NSInteger page;  //当前短信页码

- (BOOL)initEngine;

- (void)unregister;

- (void)switchNumberPad :(BOOL)hidden;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentType;  //选择

- (IBAction)switchOperation:(id)sender;
- (IBAction)writeMessage:(id)sender;

@end
