//
//  UNSipEngineInitialize.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/3.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNSipEngineInitialize.h"
#import "SipEngineManager.h"
#import "SipEngine.h"
#import "SSNetworkRequest.h"
#import "VSWManager.h"
#import <CommonCrypto/CommonDigest.h>

#import "UNPushKitMessageManager.h"


@interface UNSipEngineInitialize()<SipEngineUICallDelegate,SipEngineUIRegistrationDelegate>

@property (strong,nonatomic) NSMutableDictionary *headers;
@property (nonatomic, assign) BOOL checkToken;

@property (nonatomic, assign) BOOL isFristRegister;
@end

@implementation UNSipEngineInitialize

-(void)getBasicHeader
{
    //进行Header的构造，partner，Expries，Sign，TOKEN
    self.headers = [[NSMutableDictionary alloc] init];
    [self.headers setObject:@"2006808" forKey:@"partner"];
    
    NSString *timestemp = @"1471316792";
    [self.headers setObject:timestemp forKey:@"expires"];
    
    timestemp = [NSString stringWithFormat:@"2006808%@BAS123!@#FD1A56K",timestemp];
    [self.headers setObject:[self md5:timestemp] forKey:@"sign"];
    
    // 当前软件的版本号（从Info.plist中获得）
    NSString *key = @"CFBundleShortVersionString";
    NSString *versionNumberStr = [NSBundle mainBundle].infoDictionary[key];
    [self.headers setObject:versionNumberStr forKey:@"Version"];
    
    //附加信息
    NSString *terminalStr = @"iOS";
    [self.headers setObject:terminalStr forKey:@"Terminal"];
    
    if (self.checkToken) {
        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
        if (userdata) {
            [self.headers setObject:[userdata objectForKey:@"Token"] forKey:@"TOKEN"];
        }
    }
    
}

- (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}



+ (UNSipEngineInitialize *)sharedInstance
{
    static UNSipEngineInitialize *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nil] init];
    });
    return instance;
}

- (void)initEngine {
    UNLogLBEProcess(@"UNSipEngineInitialize---initEngine")
    
    //获取状态,如果注册失败或注册成功才重新注册
    BOOL isRegister = self.sipRegisterStatu == SipRegisterStatuCleared || self.sipRegisterStatu == SipRegisterStatuFailed;
    BOOL isCallPhone = self.sipCallPhoneStatu != SipCallPhoneStatuNewCall && self.sipCallPhoneStatu != SipCallPhoneStatuCallProcessing && self.sipCallPhoneStatu != SipCallPhoneStatuCallRinging && self.sipCallPhoneStatu != SipCallPhoneStatuCallConnected && self.sipCallPhoneStatu != SipCallPhoneStatuCallStreamsRunning;
    if (isRegister && isCallPhone) {
        NSLog(@"sipRegisterStatu=%zd===sipCallPhoneStatu=%zd", self.sipRegisterStatu, self.sipCallPhoneStatu);
        [self doRegister];
    }
    
//    if (kSystemVersionValue < 9.0) {
//        if (!self.isFristRegister) {
//            [[SipEngineManager instance] Init];
//            [[SipEngineManager instance] LoadConfig];
//            
//            if ([SipEngineManager instance].callDelegate == nil) {
//                [[SipEngineManager instance] setCallDelegate:self];
//            }
//            if ([SipEngineManager instance].registrationDelegate == nil) {
//                [[SipEngineManager instance] setRegistrationDelegate:self];
//            }
//            [self doRegister];
//            self.isFristRegister = YES;
//        }
//    }else{
//        [[SipEngineManager instance] Init];
//        [[SipEngineManager instance] LoadConfig];
//        if ([SipEngineManager instance].callDelegate == nil) {
//            [[SipEngineManager instance] setCallDelegate:self];
//        }
//        if ([SipEngineManager instance].registrationDelegate == nil) {
//            [[SipEngineManager instance] setRegistrationDelegate:self];
//        }
//        [self doRegister];
//    }
}

-(void)doRegister{
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    UNLogLBEProcess(@"UNSipEngineInitialize--doRegister");
    if(theSipEngine->AccountIsRegstered())
    {
        theSipEngine->DeRegisterSipAccount();
        __block SipEngine *callEngine = theSipEngine;
        
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetSecrityConfig params:nil success:^(id responseObj) {
            //            NSLog(@"有数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if (responseObj[@"data"][@"VswServer"]) {
                    [VSWManager shareManager].vswIp = responseObj[@"data"][@"VswServer"][@"Ip"];
                    [VSWManager shareManager].vswPort = [responseObj[@"data"][@"VswServer"][@"Port"] intValue];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Ip"] forKey:@"VSWServerIp"];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Port"] forKey:@"VSWServerPort"];
                }
                
                NSString *secpwd = [self md5:[[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"] stringByAppendingString:@"voipcc2015"]];
                
                NSString *thirdpwd = [self md5:secpwd];
                
                NSString *userName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] objectForKey:@"Tel"];
                
                
//                self.outIP = [[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"];
                UNLogLBEProcess(@"UNSipEngineInitialize--1doRegister--secpwd===%@,thirdpwd====%@,userName====%@", secpwd, thirdpwd, userName);
                callEngine->SetEnCrypt(NO, NO);
                //IP地址
                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                UNLogLBEProcess(@"apiGetSecrityConfig===%@",responseObj[@"data"])
            }
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"有异常：%@",[error description]);
        } headers:self.headers];
        
    }else{
        
        __block SipEngine *callEngine = theSipEngine;
        
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetSecrityConfig params:nil success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if (responseObj[@"data"][@"VswServer"]) {
                    [VSWManager shareManager].vswIp = responseObj[@"data"][@"VswServer"][@"Ip"];
                    [VSWManager shareManager].vswPort = [responseObj[@"data"][@"VswServer"][@"Port"] intValue];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Ip"] forKey:@"VSWServerIp"];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Port"] forKey:@"VSWServerPort"];
                }
                
                NSString *secpwd = [self md5:[[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"] stringByAppendingString:@"voipcc2015"]];
                /*
                 secpwd = [super md5:@"e38632c0f035e45efe57125bd0ebe8cevoipcc2015"];*/
                //去年替换方案
                
                NSString *thirdpwd = [self md5:secpwd];
                
                NSString *userName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] objectForKey:@"Tel"];
                UNLogLBEProcess(@"UNSipEngineInitialize--doRegister---secpwd===%@,thirdpwd====%@,userName====%@", secpwd, thirdpwd, userName)
                callEngine->SetEnCrypt(NO, NO);
                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                UNLogLBEProcess(@"apiGetSecrityConfig===%@",responseObj[@"data"])
            }
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"有异常：%@",[error description]);
        } headers:self.headers];
    }
}



#pragma mark --- SipEngineUIDelegate
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
}
-(void) OnCallProcessing{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在呼叫...")];
}

/*对方振铃*/
-(void) OnCallRinging{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"对方振铃...")];
}

/*呼叫接通*/
-(void) OnCallStreamsRunning:(bool)is_video_call{
    NSLog(@"接通...");
    //在接通时更新扩音状态
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在通话")];
}

-(void) OnCallMediaStreamsConnected:(MediaTransMode)mode{
    NSLog(@"新呼叫");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在呼叫...")];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在通话")];
}

/*话单*/
-(void) OnCallReport:(void*)report{
    
}

/*呼叫结束*/
-(void) OnCallEnded{
    NSLog(@"结束通话");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"通话结束")];
}

/*呼叫失败，并返回错误代码，代码对应的含义，请参考common_types.h*/
-(void) OnCallFailed:(CallErrorCode) error_code{
    NSLog([NSString stringWithFormat:@"呼叫错误, 代码 %d",error_code],nil);
    [[[UIAlertView alloc] initWithTitle:@"错误提示" message:[NSString stringWithFormat:@"呼叫异常,请确认网络或账号正常"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
    
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

@end
