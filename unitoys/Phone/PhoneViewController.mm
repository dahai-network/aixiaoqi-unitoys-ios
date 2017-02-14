//
//  PhoneViewController.mm
//  unitoys
//
//  Created by sumars on 16/10/25.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "PhoneViewController.h"
//#import "WriteMessageViewController.h"

#import "NewMessageViewController.h"
#import "PhoneRecordCell.h"
#import "MessageRecordCell.h"

#import "CallingViewController.h"

#import "MJViewController.h"

#import "SipEngineManager.h"

#import "MJRefresh.h"
#import "FMDatabase.h"
#import "AddressBookManager.h"
#import "ContactModel.h"
#import "CallComingInViewController.h"
#import "VSWManager.h"
#import "BlueToothDataManager.h"




@interface PhoneViewController ()
@property (nonatomic, strong)NSDictionary *userInfo;
@property (nonatomic, strong)CallComingInViewController *callCominginVC;

@end

@implementation PhoneViewController

//收到重新登入通知后，注销Sip账号
- (void)unregister {
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    
    if (theSipEngine->AccountIsRegstered()) {
        theSipEngine->DeRegisterSipAccount();
    }
    
}

- (BOOL)initEngine {
    [[SipEngineManager instance] Init];
    [[SipEngineManager instance] LoadConfig];
    
    [[SipEngineManager instance] setCallDelegate:self];
    
    [[SipEngineManager instance] setRegistrationDelegate:self];
    
    [self doRegister];
    
    [self getMaxPhoneCall];
    
    //读取本地缓存的账号信息
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    self.userInfo = [[NSDictionary alloc] initWithDictionary:userdata];
    
    //添加通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAddressBook) name:@"addressBookChanged" object:@"addressBook"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callingAction:) name:@"CallingAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeCallAction:) name:@"MakeCallAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeUnitysCallAction:) name:@"MakeUnitysCallAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessage) name:@"sendMessageSuccess" object:@"sendMessageSuccess"];
    
    return YES;
}



- (void)refreshAddressBook {
    if (_arrPhoneRecord) {
        [self.arrPhoneRecord removeAllObjects];
        [self loadPhoneRecord];
    }
    if (_arrMessageRecord) {
        self.arrMessageRecord = nil;
        [self loadMessage];
    }
}


- (BOOL) isZeroStarted :(NSString *)number {
    if (number && number.length) {
        if ([[number substringToIndex:1] isEqualToString:@"0"]) {
            return YES;
        }else{
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
    
    self.btnWriteMessage.hidden = YES;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [UIView new];
    
    
    NSString *strPhoneRecordCell = @"PhoneRecordCell";
    NSString *strMessageRecordCell = @"MessageRecordCell";
    
    UINib * phoneRecordNib = [UINib nibWithNibName:strPhoneRecordCell bundle:nil];
    UINib * messageRecordNib = [UINib nibWithNibName:strMessageRecordCell bundle:nil];
    
    [self.tableView registerNib:phoneRecordNib forCellReuseIdentifier:strPhoneRecordCell];
    [self.tableView registerNib:messageRecordNib forCellReuseIdentifier:strMessageRecordCell];
    
    if (!_arrPhoneRecord) {
        [self loadPhoneRecord];
    }
    
    self.page = 1;
    
    if (!_arrMessageRecord) {
        [self loadMessage];
    }
    // Do any additional setup after loading the view.
    
    
    __typeof(self) weakSelf = self;
    
    self.phonePadView.completeBlock = ^(NSString *btnText,NSInteger btnTag){
        //点击了删除按钮
        /*
         if (btnTag == 9) {
         [weakSelf clickDeleteBtn];
         }else if (btnTag == 11){
         //点击了完成按钮
         [weakSelf.NumKeyBoard dismiss];
         }else{
         //点击了数字按钮
         [weakSelf.textField changetext:btnText];
         }*/
        
        if (self.phonePadView.inputedPhoneNumber.length>0) {
            
            [self.segmentType setHidden:YES];
            
            
            if (self.lblPhoneNumber) {
                [self.lblPhoneNumber setHidden:NO];
                self.lblPhoneNumber.text = self.phonePadView.inputedPhoneNumber;
            } else {
                UILabel *lblPhoneNumber = [[UILabel alloc] initWithFrame:self.navigationController.navigationBar.bounds];
                
                self.lblPhoneNumber = lblPhoneNumber;
                
                [self.lblPhoneNumber setTextAlignment:NSTextAlignmentCenter];
                
                [self.lblPhoneNumber setTextColor:[UIColor whiteColor]];
                
                [self.lblPhoneNumber setBackgroundColor:[UIColor clearColor]];
                
                self.lblPhoneNumber.text = self.phonePadView.inputedPhoneNumber;
                
                [self.navigationController.navigationBar addSubview:self.lblPhoneNumber];
            }
            
            //self.title = self.phonePadView.inputedPhoneNumber;
            
            
            [weakSelf showOperation];
            
        }else{
            
            [self.segmentType setHidden:NO];
            
            if (self.lblPhoneNumber) {
                [self.lblPhoneNumber setHidden:YES];
            }
            
            if (weakSelf.callView.hidden==NO) {
                
                weakSelf.callView.hidden = YES;
            }
            
            
            
        }
        
    };
    

    /*
    [[SipEngineManager instance] Init];
    [[SipEngineManager instance] LoadConfig];
    
    [[SipEngineManager instance] setCallDelegate:self];
    
    [[SipEngineManager instance] setRegistrationDelegate:self];
    
    [self doRegister];
    
    [self getMaxPhoneCall];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callingAction:) name:@"CallingAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeCallAction:) name:@"MakeCallAction" object:nil];*/
}

//- (void)viewWillAppear:(BOOL)animated {
//    self.segmentType.selectedSegmentIndex = 0;
//    self.btnWriteMessage.hidden = YES;
//    [self.phonePadView setHidden:NO];
//    [self.tableView setNeedsUpdateConstraints];
//    [self.tableView updateConstraints];
//}

- (void)loadMessage {
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@"1",@"pageNumber", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest getRequest:apiSMSLast params:params success:^(id responseObj) {
        //
        //KV来存放数组，所以要用枚举器来处理
        /*
         NSEnumerator *enumerator = [[responseObj objectForKey:@"data"] keyEnumerator];
         id key;
         while ((key = [enumerator nextObject])) {
         [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
         }*/
        NSLog(@"查询到的用户数据：%@",responseObj);
        [self.tableView.mj_header endRefreshing];
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            _arrMessageRecord = [responseObj objectForKey:@"data"];
            [self.tableView reloadData];
            
            if (_arrMessageRecord.count>=20) {
                self.tableView.mj_footer.hidden = NO;
            }
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
    } failure:^(id dataObj, NSError *error) {
        //
        [self.tableView.mj_header endRefreshing];
    } headers:self.headers];
}

- (void)loadMoreMessage {
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@(self.page+1),@"pageNumber", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest getRequest:apiSMSLast params:params success:^(id responseObj) {
        //
        //KV来存放数组，所以要用枚举器来处理
        /*
         NSEnumerator *enumerator = [[responseObj objectForKey:@"data"] keyEnumerator];
         id key;
         while ((key = [enumerator nextObject])) {
         [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
         }*/
        NSLog(@"查询到的用户数据：%@",responseObj);
        [self.tableView.mj_header endRefreshing];
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            NSArray *arrNewMessages = [responseObj objectForKey:@"data"];
            
            if (arrNewMessages.count>0) {
                self.page = self.page + 1;
                _arrMessageRecord = [_arrMessageRecord arrayByAddingObjectsFromArray:arrNewMessages];
            }else{
                [self.tableView.mj_header endRefreshing];
                self.tableView.mj_footer.hidden = NO;
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
            
            [self.tableView reloadData];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            
        }
        
    } failure:^(id dataObj, NSError *error) {
        //
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];
    } headers:self.headers];
}


- (void)loadPhoneRecord {
    self.checkToken = YES;
    
    [self getBasicHeader];
    
    _arrPhoneRecord = [[NSMutableArray alloc] init];
    
    
    //Home目录
    //NSString *homeDirectory = NSHomeDirectory();
    
    //Document目录
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:@"callrecord.db"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    
    if (![db open]) {
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"创建通话记录失败" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return;
        
    }else{
        //监测数据库中我要需要的表是否已经存在
        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord" ];
        FMResultSet *rs = [db executeQuery:existsSql];
        
        if ([rs next]) {
            NSInteger count = [rs intForColumn:@"countNum"];
            NSLog(@"The table count: %li", count);
            if (count == 1) {
                NSLog(@"log_keepers table is existed.");
                NSString *dataSql = @"select * from CallRecord";
                FMResultSet *rs = [db executeQuery:dataSql];
                
                if ([rs columnCount]==5) { //缺少status字段
                    NSLog(@"添加数据库字段");
                    [db executeUpdate:@"ALTER TABLE CallRecord ADD COLUMN status Integer"];
                    NSString *dataSql = @"select * from CallRecord";
                    rs = [db executeQuery:dataSql];
                }
                
                while ([rs next]) {
                    //添加数据到arrPhoneCallRecord
                    NSDictionary *dicCallRecord = [[NSDictionary alloc] initWithObjectsAndKeys:[rs stringForColumn:@"hostnumber"],@"hostnumber",[rs stringForColumn:@"destnumber"],@"destnumber",[self convertDate:[rs stringForColumn:@"calltime"]],@"calltime",[rs stringForColumn:@"calltype"],@"calltype",[rs stringForColumn:@"location"],@"location",[rs stringForColumn:@"status"],@"status",nil];
                    
                    [self.arrPhoneRecord insertObject:dicCallRecord atIndex:0];
                }
                return;
            }
            
            NSLog(@"log_keepers is not existed.");
            //创建表
            //[membersDB executeUpdate:@"CREATE TABLE PersonList (Name text, Age integer, Sex integer,Phone text, Address text, Photo blob)"];
            [db executeUpdate:@"CREATE TABLE CallRecord (hostnumber Text, destnumber Text, calltime TimeStamp, calltype Text, location Text, status Integer)"];
        }else{
            //加载数据到列表
            
            NSString *dataSql = @"select * from CallRecord";
            FMResultSet *rs = [db executeQuery:dataSql];
            
            while ([rs next]) {
                //添加数据到arrPhoneCallRecord
                NSDictionary *dicCallRecord = [[NSDictionary alloc] initWithObjectsAndKeys:[rs stringForColumn:@"hostnumber"],@"hostnumber",[rs stringForColumn:@"destnumber"],@"destnumber",[self convertDate:[rs stringForColumn:@"calltime"]],@"calltime",[rs stringForColumn:@"calltype"],@"calltype",[rs stringForColumn:@"location"],@"location",[rs stringForColumn:@"status"],@"status",nil];
                
                [self.arrPhoneRecord insertObject:dicCallRecord atIndex:0];
            }
            
            
        }
        
        [rs close];
    }
    //            [[NSBundle mainBundle] pathForResource:@"https" ofType:@"cer"];
    
    
    [self.tableView reloadData];
}

- (NSString *)numberFromCid :(NSString *)cid {
    //原本考虑正则，但规则比较简单
    
    if (([[cid substringToIndex:3] isEqualToString:@"981"])&&[cid rangeOfString:@"#"].length) {
        return [cid substringWithRange:NSMakeRange(3, [cid rangeOfString:@"#"].location-3)];
    } else if ([[cid substringToIndex:3] isEqualToString:@"986"]) {
        return [cid substringFromIndex:8];
    } else {
        return cid;
    }
}

- (BOOL)addPhoneRecord :(NSString *)hostcid :(NSString *)destcid :(NSDate *)calltime :(NSString *)calltype {
    
//    NSMutableDictionary *dicPhoneRecord = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[self compareCurrentTime:calltime],@"calltime",calltype,@"calltype",[self numberFromCid:hostcid],@"hostnumber",[self numberFromCid:destcid],@"destnumber", nil];
    NSMutableDictionary *dicPhoneRecord = [[NSMutableDictionary alloc] initWithObjectsAndKeys:calltime,@"calltime",calltype,@"calltype",[self numberFromCid:hostcid],@"hostnumber",[self numberFromCid:destcid],@"destnumber",@0,@"status", nil];  //时间写入记录时不需要转成字符
    
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"location" ofType:@"db"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    
    if (![db open]) {
        
        NSLog(@"数据库打开失败！");
        
    }else{
        NSString *number;
        if ([calltype isEqualToString:@"去电"]) {
            number = [dicPhoneRecord objectForKey:@"destnumber"];
        } else {
            number = [dicPhoneRecord objectForKey:@"hostnumber"];
        }
        
            
            //NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithDictionary:dicPhoneRecord copyItems:YES];
            
            [dicPhoneRecord setObject:@"未知" forKey:@"location"];
            
            //                    number = @"18805061112";
            
            if ([self isZeroStarted:number]) {
                
                NSString *prefix;
                if ([[number substringToIndex:2] isEqualToString:@"01"]) {
                    prefix = [number substringToIndex:3];
                }else if ([[number substringToIndex:2] isEqualToString:@"02"]) {
                    prefix = [number substringToIndex:3];
                } else {
                    prefix = [number substringToIndex:4];
                }
                
                NSString *cityid;
                NSString *provinceid;
                
                FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM number_%@ limit %d,1",@"0",[prefix intValue]-1]];
                if ([rs next]) {
                    cityid = [NSString stringWithFormat:@"%d",[rs intForColumnIndex:0]];
                }
                
                rs = [db executeQuery:[NSString stringWithFormat:@"SELECT province_id FROM city where _id=%@",cityid]];
                if ([rs next]) {
                    provinceid = [NSString stringWithFormat:@"%d",[rs intForColumnIndex:0]];
                }
                
                rs = [db executeQuery:[NSString stringWithFormat:@"SELECT province,city FROM province,city where _id=%@ and id=%@",cityid,provinceid]];
                if ([rs next]) {
                    [dicPhoneRecord setObject:[NSString stringWithFormat:@"%@ %@",[rs stringForColumn:@"province"],[rs stringForColumn:@"city"]] forKey:@"type"];
                }
                
                
            }else{
                
                if ([number length]>=8) {
//                    [self.arrPhoneRecord insertObject:dicPhoneRecord atIndex:0];
                    NSString *prefix = [number substringToIndex:3];
                    NSString *center = [number substringWithRange:{3,4}];
                    
                    NSString *cityid;
                    NSString *provinceid;
                    
                    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM number_%@ limit %@,1",prefix,center]];
                    if ([rs next]) {
                        cityid = [NSString stringWithFormat:@"%d",[rs intForColumnIndex:0]];
                    }
                    
                    rs = [db executeQuery:[NSString stringWithFormat:@"SELECT province_id FROM city where _id=%@",cityid]];
                    if ([rs next]) {
                        provinceid = [NSString stringWithFormat:@"%d",[rs intForColumnIndex:0]];
                    }
                    
                    rs = [db executeQuery:[NSString stringWithFormat:@"SELECT province,city FROM province,city where _id=%@ and id=%@",cityid,provinceid]];
                    if ([rs next]) {
                        [dicPhoneRecord setObject:[NSString stringWithFormat:@"%@ %@",[rs stringForColumn:@"province"],[rs stringForColumn:@"city"]] forKey:@"location"];
                    }
                    NSLog(@"%@",center,nil);
                }
                
            }
            
            
            [self.arrPhoneRecord insertObject:dicPhoneRecord atIndex:0];
        
        [self.tableView reloadData];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:@"callrecord.db"];
    
    db = [FMDatabase databaseWithPath:path];
    
    if (![db open]) {
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"创建通话记录失败" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return FALSE;
        
    }else{
        //监测数据库中我要需要的表是否已经存在
        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord" ];
        FMResultSet *rs = [db executeQuery:existsSql];
        
        if ([rs next]) {
            NSInteger count = [rs intForColumn:@"countNum"];
            NSLog(@"The table count: %li", count);
            if (count == 1) {
                NSLog(@"log_keepers table is existed.");
                //添加记录
                NSInteger a=[calltime timeIntervalSince1970];
                NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
                BOOL success = [db executeUpdate:@"INSERT INTO CallRecord (hostnumber, destnumber, calltime, calltype, location, status) VALUES (?, ?, ?, ?, ?, ?)", [dicPhoneRecord objectForKey:@"hostnumber"], [dicPhoneRecord objectForKey:@"destnumber"], timestemp,[dicPhoneRecord objectForKey:@"calltype"],[dicPhoneRecord objectForKey:@"location"],[dicPhoneRecord objectForKey:@"status"]];
                
                if (!success) {
                    NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
                }
                //return TRUE;
            }
            
            NSLog(@"log_keepers is not existed.");
            //创建表
            //[membersDB executeUpdate:@"CREATE TABLE PersonList (Name text, Age integer, Sex integer,Phone text, Address text, Photo blob)"];
            [db executeUpdate:@"CREATE TABLE CallRecord (hostnumber Text, destnumber Text, calltime TimeStamp, calltype text, location Text, status Integer)"];
        }else{
            //添加记录
            NSInteger a=[calltime timeIntervalSince1970];
            NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
            BOOL success = [db executeUpdate:@"INSERT INTO CallRecord (hostnumber, destnumber, calltime, calltype, location, status) VALUES (?, ?, ?, ?, ?, ?)", [dicPhoneRecord objectForKey:@"hostnumber"], [dicPhoneRecord objectForKey:@"destnumber"], timestemp,[dicPhoneRecord objectForKey:@"calltype"],[dicPhoneRecord objectForKey:@"location"],[dicPhoneRecord objectForKey:@"status"]];
            
            if (!success) {
                NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
            }
            
        }
        
        [rs close];
    }
    return YES;
}

- (void)makeCallAction :(NSNotification *)notification {
    
    
        NSString *phoneNumber = notification.object;
    
        if (phoneNumber) {
            [self callNumber:phoneNumber];
        }
    
    
}

- (void)makeUnitysCallAction:(NSNotification *)notification {
    NSString *phoneNumber = notification.object;
    
    if (phoneNumber) {
        [self callUnitysNumber:phoneNumber];
    }
}

- (void)getMaxPhoneCall {
    self.checkToken = YES;
    [SSNetworkRequest getRequest:apiGetMaxmimumPhoneCallTime params:nil success:^(id responseObj) {
        NSLog(@"有数据：%@",responseObj);
        
        
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            self.maxPhoneCall = [[[responseObj objectForKey:@"data"]  objectForKey:@"maximumPhoneCallTime"] intValue];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        
        
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"有异常：%@",[error description]);
    } headers:self.headers];
}

- (void)callingAction :(NSNotification *)notification {
    if (notification.object) {
        NSString *action = notification.object;
        
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        if ([action isEqualToString:@"Hungup"]) {
            //
            
            if(theSipEngine->InCalling())
            theSipEngine->TerminateCall();
            
            
            self.callStopTime = [NSDate date];
            
            self.hostHungup = @"source";
            
//            [self endingCallOut];
            
            
            
        }else if ([action isEqualToString:@"SwitchSound"]){
            NSLog(@"当前扩音状态:%zd", self.speakerStatus);
            //
            self.speakerStatus = !self.speakerStatus;
            theSipEngine->SetLoudspeakerStatus(self.speakerStatus);
        }else if ([action isEqualToString:@"MuteSound"]){
            NSLog(@"MuteSound");
            self.muteStatus = !self.muteStatus;
            theSipEngine->MuteMic(self.muteStatus);
        }else if ([action isEqualToString:@"Answer"]){
            NSLog(@"Answer");
            //选择最后一条，更新为
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *path = [paths objectAtIndex:0];
            
            path = [path stringByAppendingPathComponent:@"callrecord.db"];
            
            FMDatabase *db = [FMDatabase databaseWithPath:path];
            
            if (![db open]) {
                [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"创建通话记录失败" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
            }else{
//                FMResultSet *rs = [db executeQuery:@"select top 1 calltime from CallRecord"];// order by calltime desc"];
                FMResultSet *rs = [db executeQuery:@"select * from CallRecord order by calltime desc limit 0,1"];// order by calltime desc"];
                
                if ([rs next]) {
                    [db executeUpdate:@"update CallRecord set status=1 where calltime=?",[rs stringForColumn:@"calltime"]];

                }
                
            }
            [self loadPhoneRecord];
            [self.tableView reloadData];

            theSipEngine->AnswerCall();
            theSipEngine->StopRinging();
            
        }else if ([action isEqualToString:@"Refuse"]){
            theSipEngine->TerminateCall();
        }
    }
}

-(void) OnNetworkQuality:(int)ms {
    //网络质量提示？
}

-(void)OnSipEngineState:(SipEngineState)code {
    if (code==0) {
        //
    } else {
        //
    }
}

-(void) OnNewCall:(CallDir)dir
 withPeerCallerID:(NSString*)cid
        withVideo:(BOOL)video_call{
    NSString *msg = @"";
    NSString *newcid;
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    
    if (dir == CallIncoming){
        msg = [NSString stringWithFormat:@"新来电 %@",cid];
        //去掉“+”
        if ([cid containsString:@"+"]) {
            newcid = [cid stringByReplacingOccurrencesOfString:@"+" withString:@""];
            cid = newcid;
        }
        //去掉86
        if ([[cid substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"86"]) {
            newcid = [cid substringFromIndex:2];
            cid = newcid;
        }
        self.callCominginVC = [[CallComingInViewController alloc] init];
        self.callCominginVC.nameStr = [self checkLinkNameWithPhoneStr:cid];
        [self.navigationController presentViewController:self.callCominginVC animated:YES completion:nil];
        
        [self addPhoneRecord:cid :[userdata objectForKey:@"Tel"] :[NSDate date] :@"来电"];
        
        /*
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        
        theSipEngine->start*/
        //        [mBtnDial setTitle:@"接听" forState:UIControlStateNormal];
    }else{
        msg = [NSString stringWithFormat:@"新去电 %@",cid];
        
        [self addPhoneRecord:[userdata objectForKey:@"Tel"] :cid :[NSDate date] :@"去电"];
    }
    
    //    [mStatus setText:msg];
}

-(void) OnCallProcessing{
    //    NSLog(@"正在接续...");
    //    [mStatus setText:@"正在接续..."];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:@"正在呼叫..."];
}

/*对方振铃*/
-(void) OnCallRinging{
//        NSLog(@"对方振铃...");
    //    [mStatus setText:@"对方振铃..."];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:@"对方振铃..."];
}

/*呼叫接通*/
-(void) OnCallStreamsRunning:(bool)is_video_call{
        NSLog(@"接通...");
    //    [mStatus setText:@"呼叫接通"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:@"正在通话"];
}

-(void) OnCallMediaStreamsConnected:(MediaTransMode)mode{
    //    NSLog(@"接通...");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:@"正在呼叫..."];
    //    [mStatus setText:@"媒体接通"];
}

-(void) OnCallResume {
    NSLog(@"继续通话");
}

-(void) onCallResumeByRemote {
    //远程
    NSLog(@"对方继续通话");
}

-(void) OnCallPaused {
    NSLog(@"暂停通话");
}

-(void) onCallPausedByRemote {
    NSLog(@"对方暂停通话");
}

-(void) OnCallRemotePaused {
    NSLog(@"暂停通话");
}

/*呼叫接通知识*/
-(void) OnCallConnected{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:@"正在通话"];
}

/*话单*/
-(void) OnCallReport:(void*)report{
    
}

/*呼叫结束*/
-(void) OnCallEnded{
    //    NSLog(@"结束通话");
    //    [mStatus setText:@"结束通话"];
    
    [self loadPhoneRecord];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:@"通话结束"];
    /*
    //移除来电页面
    if (self.callCominginVC) {
        [self.callCominginVC dismissViewControllerAnimated:YES completion:nil];
    }*/
}

/*呼叫失败，并返回错误代码，代码对应的含义，请参考common_types.h*/
-(void) OnCallFailed:(CallErrorCode) error_code{
    NSLog([NSString stringWithFormat:@"呼叫错误, 代码 %d",error_code],nil);
    [[[UIAlertView alloc] initWithTitle:@"错误提示" message:[NSString stringWithFormat:@"呼叫错误, 代码 %d",error_code] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
    //    [mStatus setText:[NSString stringWithFormat:@"呼叫错误, 代码 %d",error_code]];
    
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
-(void)doRegister{
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    
    if(theSipEngine->AccountIsRegstered())
    {
        theSipEngine->DeRegisterSipAccount();
        __block SipEngine *callEngine = theSipEngine;
        
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetSecrityConfig params:nil success:^(id responseObj) {
            NSLog(@"有数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if (responseObj[@"data"][@"VswServer"]) {
                    [VSWManager shareManager].vswIp = responseObj[@"data"][@"VswServer"][@"Ip"];
                    [VSWManager shareManager].vswPort = [responseObj[@"data"][@"VswServer"][@"Port"] intValue];
                }
                
                NSString *secpwd = [super md5:[[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"] stringByAppendingString:@"voipcc2015"]];
 
                NSString *thirdpwd = [super md5:secpwd];
                
                NSString *userName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] objectForKey:@"Tel"];

                
                self.outIP = [[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"];
                
                callEngine->SetEnCrypt(NO, NO);
                //IP地址
                                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                //域名
//                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [@"asterisk.unitoys.com" UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
            
            
            
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"有异常：%@",[error description]);
        } headers:self.headers];
        
    }else{

        __block SipEngine *callEngine = theSipEngine;
        
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetSecrityConfig params:nil success:^(id responseObj) {
            NSLog(@"有数据：%@",responseObj);
            
            
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if (responseObj[@"data"][@"VswServer"]) {
                    [VSWManager shareManager].vswIp = responseObj[@"data"][@"VswServer"][@"Ip"];
                    [VSWManager shareManager].vswPort = [responseObj[@"data"][@"VswServer"][@"Port"] intValue];
                }
                
                NSString *secpwd = [super md5:[[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"] stringByAppendingString:@"voipcc2015"]];
            /*
            secpwd = [super md5:@"e38632c0f035e45efe57125bd0ebe8cevoipcc2015"];*/
            //去年替换方案
            
                NSString *thirdpwd = [super md5:secpwd];
            
                NSString *userName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] objectForKey:@"Tel"];
            //[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"]
            
            //callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String],"", "121.46.3.20", 65061,1800);
                
                self.outIP = [[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"];
                
//                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String],"", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue],1800);
                callEngine->SetEnCrypt(NO, NO);
                //IP地址
                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                //域名
//                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [@"asterisk.unitoys.com" UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
            
            
            
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"有异常：%@",[error description]);
        } headers:self.headers];
        
        /*
         #define CRYPT
         
         #ifdef CRYPT
         theSipEngine->RegisterSipAccount([@"18850161016" UTF8String], [@"18850161016" UTF8String],"", "121.46.3.20", 65061,1800);
         #else
         theSipEngine->RegisterSipAccount([@"18850161016" UTF8String], [@"18850161016" UTF8String],"", "121.46.3.20", 65060,1800);
         #endif */
    }
}

/*帐号注册状态反馈, 失败返回错误代码 代码对应的含义，请参考common_types.h*/
-(void) OnRegistrationState:(RegistrationState) code
              withErrorCode:(RegistrationErrorCode) e_errno{
    
    NSString *msg=@"";
    
    if(code == 1){
        msg = @"正在注册...";
        [SipEngineManager instance].resignStatue = 0;
        //        [mBtnRegister setTitle:@"注册中" forState:UIControlStateNormal];
    }else if(code == 2){
        msg = @"注册成功！";
        [SipEngineManager instance].resignStatue = 1;
        //        [mBtnRegister setTitle:@"注销" forState:UIControlStateNormal];
    }else if(code == 3){
        msg = @"您的账号已注销";
        [SipEngineManager instance].resignStatue = 0;
        //        [mBtnRegister setTitle:@"注册" forState:UIControlStateNormal];
    }else if(code == 4){
        msg = [NSString stringWithFormat:@"注册失败，错误代码 %d",e_errno];
        [SipEngineManager instance].resignStatue = 0;
        //        [mBtnRegister setTitle:@"注册" forState:UIControlStateNormal];
    }
    
    //    [mStatus setText:msg];
    NSLog(@"注册状态：%@",msg);
}

/*
- (void)normalCall {
    if (self.phoneNumber) {
        NSString *num = [[NSString alloc] initWithFormat:@"telprompt://%@",self.phoneNumber]; //而这个方法则打电话前先弹框  是否打电话 然后打完电话之后回到程序中 网上说这个方法可能不合法 无法通过审核
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:num]];
        
        self.typeView.hidden = YES;
    }
    
    
    
}

- (void)networkCall {
    
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    if (storyboard) {
        
        
        CallingViewController *callingViewController = [storyboard instantiateViewControllerWithIdentifier:@"callingViewController"];
        if (callingViewController) {
            self.typeView.hidden = YES;
            callingViewController.lblCallingInfo.text = self.phoneNumber;
            [self presentViewController:callingViewController animated:YES completion:^{
                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                
                theSipEngine->MakeCall([[NSString stringWithFormat:@"971%@#60",self.phoneNumber] UTF8String],false,NULL);
            }];
        }
    }
}*/



- (void)showOperation {
    
    if (self.callView) {
        //重置拨打图标
        [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pushon"] forState:UIControlStateNormal];
        
        [self.callView setHidden:NO];
        [self.tabBarController.tabBar bringSubviewToFront:self.callView];
    }else{
        // Instantiate the nib content without any reference to it.
        NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"PhoneOperationPad" owner:nil options:nil];
        
        // Find the view among nib contents (not too hard assuming there is only one view in it).
        PhoneOperationPad *callView = [nibContents lastObject];
        
        [callView setFrame:self.tabBarController.tabBar.bounds];
        //callView.deleteNumberBlock
        callView.hidden = NO;
        [self.tabBarController.tabBar addSubview:callView];
        self.callView = callView;
//        [self.tabBarController.tabBar bringSubviewToFront:self.callView];
        
        self.callView.deleteNumberBlock = ^(){
            if (self.phonePadView) {
                if (self.phonePadView.inputedPhoneNumber.length>1) {
                    self.phonePadView.inputedPhoneNumber = [self.phonePadView.inputedPhoneNumber substringToIndex:self.phonePadView.inputedPhoneNumber.length-1];
                    
                    self.lblPhoneNumber.text = self.phonePadView.inputedPhoneNumber;
                    
                }else{
                    self.phonePadView.inputedPhoneNumber = @"";
                    [self.segmentType setHidden:NO];
                    
                    if (self.lblPhoneNumber) {
                        [self.lblPhoneNumber setHidden:YES];
                    }
                    
                    if (self.callView.hidden==NO) {
                        
                        self.callView.hidden = YES;
                    }
                    
                    
                }
                
                
            }
        };
        
        self.callView.calloutBlock = ^(){
            [self standardCall];
        };
        
        self.callView.switchStatusBlock = ^(BOOL hidden) {
            if (hidden) {
                //开始加载谁
                [self switchNumberPad:YES];
//                [self.phonePadView setHidden:YES];
                [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pulloff"] forState:UIControlStateNormal];
 
            }else{
                
//                [self.phonePadView setHidden:NO];
                [self switchNumberPad:NO];
                [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pushon"] forState:UIControlStateNormal];
                
            }
            
        };
    }
    /*
    NSLog(@"数据：%@",weakSelf.view);
    UIView *callView = [[UIView alloc] initWithFrame:CGRectMake(0, weakSelf.tableView.bounds.size.height-30, 100, 30)];
    callView.backgroundColor = [UIColor redColor];
    
    [weakSelf.view addSubview:callView];*/
}

- (void)standardCall {
    NSString *strPhoneNumber = self.phonePadView.inputedPhoneNumber;
    self.phonePadView.inputedPhoneNumber = nil;
    self.lblPhoneNumber.text = nil;
//    [self showOperation];
    self.lblPhoneNumber.hidden = YES;
    self.segmentType.hidden = NO;
    self.callView.hidden = YES;
    
//    if ([strPhoneNumber length]>=8) {
        [self callNumber:[self formatPhoneNum:strPhoneNumber]];
//    }
}

- (NSString *)formatPhoneNum:(NSString *)phone
{
    
    phone = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([phone hasPrefix:@"86"]) {
        NSString *formatStr = [phone substringWithRange:NSMakeRange(2, [phone length]-2)];
        return formatStr;
    }
    else if ([phone hasPrefix:@"+86"])
    {
        if ([phone hasPrefix:@"+86·"]) {
            NSString *formatStr = [phone substringWithRange:NSMakeRange(4, [phone length]-4)];
            return formatStr;
        }
        else
        {
            NSString *formatStr = [phone substringWithRange:NSMakeRange(3, [phone length]-3)];
            return formatStr;
        }
    }
    return phone;
}

- (void)callNumber :(NSString *)strNumber {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    
    if (storyboard) {
        if (!strNumber) {
            self.phoneNumber= self.phonePadView.inputedPhoneNumber;
        }else{
            self.phoneNumber = strNumber;
        }
        self.calledTelNum = [NSString stringWithFormat:@"981%@",self.phoneNumber];
        
        CallingViewController *callingViewController = [storyboard instantiateViewControllerWithIdentifier:@"callingViewController"];
        if (callingViewController) {
            self.callStartTime = [NSDate date];
            callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
            [self presentViewController:callingViewController animated:YES completion:^{
                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
                theSipEngine->MakeCall([[NSString stringWithFormat:@"981%@#%d",[self formatPhoneNum:self.phoneNumber],self.maxPhoneCall] UTF8String],false,NULL);
            }];
        }
    }
    
}

- (void)callUnitysNumber :(NSString *)strNumber {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    
    if (storyboard) {
        if (!strNumber) {
            self.phoneNumber= self.phonePadView.inputedPhoneNumber;
        }else{
            self.phoneNumber = strNumber;
        }
        self.calledTelNum = [NSString stringWithFormat:@"986%@",self.phoneNumber];
        
        CallingViewController *callingViewController = [storyboard instantiateViewControllerWithIdentifier:@"callingViewController"];
        if (callingViewController) {
            self.callStartTime = [NSDate date];
            callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
            [self presentViewController:callingViewController animated:YES completion:^{
                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
                theSipEngine->MakeCall([[NSString stringWithFormat:@"986%@%@",[VSWManager shareManager].callPort, [self formatPhoneNum:self.phoneNumber]] UTF8String],false,NULL);
            }];
        }
    }
    
}

- (void)endingCallOut {
    self.checkToken = YES;
    //    ;
    //
    int dat = [self.callStopTime timeIntervalSinceReferenceDate]-[self.callStartTime timeIntervalSinceReferenceDate];
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    
    
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[userdata objectForKey:@"Tel"],@"DeviceName",self.calledTelNum,@"calledTelNum",[self formatTime:self.callStartTime],@"callStartTime", [self formatTime:self.callStopTime],@"callStopTime",[NSString stringWithFormat:@"%d",dat],@"callSessionTime",self.outIP,@"callSourceIp",self.outIP,@"callServerIp",self.hostHungup,@"acctterminatedirection",nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiAddSpeakRecord params:params success:^(id responseObj) {

        
        NSLog(@"查询到的记录添加：%@",responseObj);
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
//            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            NSLog(@"通话记录添加成功");
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)switchNumberPad :(BOOL)hidden {
    
    [self.tableView setNeedsLayout];
    [self.tableView layoutIfNeeded];
    
    if (hidden) {
        NSLog(@"关闭键盘");
//        NSLog(@"y值---%.2f", self.self.phonePadView.frame.origin.y);
//        [self.phonePadView setFrame:CGRectMake(self.phonePadView.frame.origin.x, self.phonePadView.frame.origin.y+self.phonePadView.frame.size.height, self.phonePadView.frame.size.width, 0)];
        [self.phonePadView setFrame:CGRectMake(0, kScreenHeightValue - 64 - 49, self.phonePadView.frame.size.width, 0)];
        
        self.numberPadStatus = YES;
    }else{
        NSLog(@"打开键盘");
//        [self.phonePadView setFrame:CGRectMake(self.phonePadView.frame.origin.x, self.phonePadView.frame.origin.y-201, self.phonePadView.frame.size.width, 201)];
        [self.phonePadView setFrame:CGRectMake(0, kScreenHeightValue - 64 - 49 - 225, self.phonePadView.frame.size.width, 225)];
        
        self.numberPadStatus = NO;
    }
    
    self.callView.isPadHidden = self.numberPadStatus;

    
    //[self.tableView needsUpdateConstraints];
    
}


- (IBAction)switchOperation:(id)sender {
    
    if (self.callActionView)  self.callActionView.hidden = YES; //切换过程中隐藏电话拨号的弹出面板
    
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    
    self.phoneOperation = seg.selectedSegmentIndex;
    
    if (seg.selectedSegmentIndex==0) {
        //开始加载
        [self.btnWriteMessage setHidden:YES];
        
        [self.phonePadView setHidden:NO];
        [self switchNumberPad:NO];
        [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pulloff"] forState:UIControlStateNormal];
        //点击拨打按钮时tabbarItem状态更新
        [self.navigationController.tabBarItem setImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
        [self.navigationController.tabBarItem setSelectedImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
        
        self.tableView.mj_header = nil;
        
        self.tableView.mj_footer = nil;
        
    }else{
        if(self.callView){
            [self.callView setHidden:YES];
        }
        [self.btnWriteMessage setHidden:NO];
        
        [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pushon"] forState:UIControlStateNormal];
        [self.phonePadView setHidden:YES];
        
        self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            //Call this Block When enter the refresh status automatically
            self.arrMessageRecord = nil;
            self.page = 1;
            [self loadMessage];
            
        }];
        
//        [self.tableView.mj_header beginRefreshing];

        //刷新尾部
        self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreMessage)];
        //防止网络慢的时候，显示脚部刷新，进入隐藏
        self.tableView.mj_footer.hidden = YES;
        //不加载
    }
    [self.tableView reloadData];
}

- (IBAction)writeMessage:(id)sender {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    NewMessageViewController *newMessageViewController = [mainStory instantiateViewControllerWithIdentifier:@"newMessageViewController"];
    if (newMessageViewController) {
        
        //        writeMessageViewController.destNumber = [dicPackage objectForKey:@"PackageId"];
        [self.navigationController pushViewController:newMessageViewController animated:YES];
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.phoneOperation==0) {
        return self.arrPhoneRecord.count;
    }else{
        return self.arrMessageRecord.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.phoneOperation==0) {
        PhoneRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PhoneRecordCell"];
        
        NSDictionary *dicPhoneRecord = [self.arrPhoneRecord objectAtIndex:indexPath.row];
        
        
        cell.lblCallTime.text = [self compareCurrentTime:[dicPhoneRecord objectForKey:@"calltime"]];
        
        cell.lblPhoneType.text = [dicPhoneRecord objectForKey:@"type"];
        
        [cell.lblPhoneNumber setTextColor:[UIColor blackColor]];

        if ([[dicPhoneRecord objectForKey:@"calltype"] isEqualToString:@"来电"]) {
            [cell.ivStatus setImage:[UIImage imageNamed:@"tel_callin"]];
            
            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
            
            if ([cell.lblCallTime.text isEqualToString:@"刚刚"]) {
                NSLog(@"有了：%@",dicPhoneRecord);
            }
            
            if ([[dicPhoneRecord objectForKey:@"status"] intValue]==0){  //如果未接听则显示红色
                [cell.lblPhoneNumber setTextColor:[UIColor redColor]];
            }
            
        }else{
            [cell.ivStatus setImage:[UIImage imageNamed:@"tel_callout"]];
            
            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
            
            
        }
        
        
            
        
        cell.lblPhoneType.text = [dicPhoneRecord objectForKey:@"location"];

        return cell;
    }else{
        MessageRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"MessageRecordCell"];
        
        NSDictionary *dicMessageRecord = [self.arrMessageRecord objectAtIndex:indexPath.row];
        
        if ([dicMessageRecord[@"To"] isEqualToString:self.userInfo[@"Tel"]]) {
            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicMessageRecord objectForKey:@"Fm"]];
        } else {
            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicMessageRecord objectForKey:@"To"]];
        }
        
        cell.lblMessageDate.text = [self compareCurrentTime:[self convertDate:[dicMessageRecord objectForKey:@"SMSTime"]]];
        
        cell.lblContent.text = [dicMessageRecord objectForKey:@"SMSContent"];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.phoneOperation==0) {
        return 60;
    }else{
        return 80;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.phoneOperation==0) {
        //电话记录，拨打电话
        if (!self.callActionView){
            self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-44)];
            
            [self.view addSubview:self.callActionView];
        }
        
        
        __weak typeof(self) weakSelf = self;
        
        self.callActionView.cancelBlock = ^(){
            weakSelf.callActionView.hidden = YES;
        };
        
        self.callActionView.actionBlock = ^(NSInteger callType){
            weakSelf.callActionView.hidden = YES;
            if (callType==1) {
                //网络电话
                //电话记录，拨打电话
                NSDictionary *dicCallRecord = [weakSelf.arrPhoneRecord objectAtIndex:indexPath.row];
                if (dicCallRecord) {
                    if ([dicCallRecord[@"calltype"] isEqualToString:@"来电"]) {
                        [weakSelf callNumber:[dicCallRecord objectForKey:@"hostnumber"]];
                    } else if ([dicCallRecord[@"calltype"] isEqualToString:@"去电"]) {
                        [weakSelf callNumber:[dicCallRecord objectForKey:@"destnumber"]];
                    } else {
                        //                HUDNormal(@"无法识别的电话方式")
                        NSLog(@"无法识别的电话方式");
                    }
                    NSLog(@"%@", dicCallRecord[@"calltype"]);
                }
            }else if (callType==2){
                //手环电话
                if ([BlueToothDataManager shareManager].isRegisted) {
                    //电话记录，拨打电话
                    NSDictionary *dicCallRecord = [weakSelf.arrPhoneRecord objectAtIndex:indexPath.row];
                    if (dicCallRecord) {
                        if ([dicCallRecord[@"calltype"] isEqualToString:@"来电"]) {
                            [weakSelf callUnitysNumber:[dicCallRecord objectForKey:@"hostnumber"]];
                        } else if ([dicCallRecord[@"calltype"] isEqualToString:@"去电"]) {
                            [weakSelf callUnitysNumber:[dicCallRecord objectForKey:@"destnumber"]];
                        } else {
                            //                HUDNormal(@"无法识别的电话方式")
                            NSLog(@"无法识别的电话方式");
                        }
                        NSLog(@"%@", dicCallRecord[@"calltype"]);
                    }
                } else {
                    HUDNormal(@"手环内sim卡未注册或已掉线")
                }
            }
        };
        
        self.callActionView.hidden = NO;
        
        
    } else {
        //消息记录，显示消息
        
        NSDictionary *dicMessageRecord = [_arrMessageRecord objectAtIndex:indexPath.row];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
        
        if (storyboard) {
            
//            self.phoneNumber= self.phonePadView.lblPhoneNumber.text;
            
            MJViewController *MJViewController = [storyboard instantiateViewControllerWithIdentifier:@"MJViewController"];
            if (MJViewController) {
                if ([dicMessageRecord[@"To"] isEqualToString:self.userInfo[@"Tel"]]) {
                    MJViewController.title = [self checkLinkNameWithPhoneStr:[dicMessageRecord objectForKey:@"Fm"]];
                    MJViewController.toTelephone = [dicMessageRecord objectForKey:@"Fm"];
                } else {
                    MJViewController.title = [self checkLinkNameWithPhoneStr:[dicMessageRecord objectForKey:@"To"]];
                    MJViewController.toTelephone = [dicMessageRecord objectForKey:@"To"];
                }
                MJViewController.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:MJViewController animated:YES];
                
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"错误提示"]) {
        [self OnCallEnded];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"sendMessageSuccess" object:@"sendMessageSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addressBookChanged" object:@"addressBook"];
}
@end
