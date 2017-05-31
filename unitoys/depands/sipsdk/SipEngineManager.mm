#import "SipEngineManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import "ContactModel.h"
#import "AddressBookManager.h"

static SipEngine* theSipEngine=nil;
static SipEngineManager* theSipEngineManager=nil;
static bool NetworkReachable=false;

void networkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void * info) {
    NSLog(@"Network connection flag [%x]",flags);
    
    //	SipEngineManager* lSipEngineMgr = (SipEngineManager*)CFBridgingRelease(info);
    SipEngineManager* lSipEngineMgr = (__bridge SipEngineManager*)info;
    
    SCNetworkReachabilityFlags networkDownFlags=kSCNetworkReachabilityFlagsConnectionRequired |kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand;
    
    
    
    if ([SipEngineManager getSipEngine] != nil) {
        if ((flags == 0) | (flags & networkDownFlags)) {
            [[SipEngineManager instance] kickOffNetworkConnection];
            lSipEngineMgr->connectivity = none;
            
            if(NetworkReachable)
                [SipEngineManager getSipEngine]->SetNetworkReachable(false);
            
            NetworkReachable = false;
        } else {
            Connectivity  newConnectivity = flags & kSCNetworkReachabilityFlagsIsWWAN ? wwan:wifi;
            if (lSipEngineMgr->connectivity == none) {
                //connectivity changed from none
                [SipEngineManager getSipEngine]->SetNetworkReachable(true);
                
                if([SipEngineManager getSipEngine]->InCalling()){ /*如果正在通话，切换完成后自动转为 relay 模式*/
                    NSLog(@"connectivity has changed and incalling, need to foce relay media!");
                }
            } else if (lSipEngineMgr->connectivity != newConnectivity) {
                // connectivity has changed, need to foce register
                
                [SipEngineManager getSipEngine]->SetNetworkReachable(false);
                [SipEngineManager getSipEngine]->ForceReRegster();
                [SipEngineManager getSipEngine]->SetNetworkReachable(true);
                
                if([SipEngineManager getSipEngine]->InCalling()){ /*如果正在通话，切换完成后自动转为 relay 模式*/
                    NSLog(@"connectivity has changed and incalling, need to foce relay media!");
                }
            }
            
            NetworkReachable =true;
            lSipEngineMgr->connectivity=newConnectivity;
            NSLog(@"new network connectivity  of type [%s]",(newConnectivity==wifi?"wifi":"wwan"));
        }
        
    }
}

@implementation SipEngineManager

@synthesize callDelegate;
@synthesize registrationDelegate;
@synthesize vibrateTimer;

-(id) init {
    if ((self= [super init])) {
    }
    return self;
}

-(BOOL)NetworkIsReachable{
    return NetworkReachable;
}

-(void)setProxyReachability{
    
    const char *nodeName="8.8.8.8";
    
    if (proxyReachability) {
        NSLog(@"Cancelling old network reachability");
        SCNetworkReachabilityUnscheduleFromRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(proxyReachability);
        proxyReachability = nil;
    }
    
    proxyReachability=SCNetworkReachabilityCreateWithName(nil, nodeName);
    proxyReachabilityContext.info=(__bridge void *)self;
    //initial state is network off should be done as soon as possible
    SCNetworkReachabilityFlags flags;
    if (!SCNetworkReachabilityGetFlags(proxyReachability, &flags)) {
        NSLog(@"Cannot get reachability flags");
    };
    
    CFRunLoopRef main_run_loop = [[NSRunLoop mainRunLoop] getCFRunLoop];
    
    networkReachabilityCallBack(proxyReachability,flags,(__bridge void *)self);
    
    if (!SCNetworkReachabilitySetCallback(proxyReachability, (SCNetworkReachabilityCallBack)networkReachabilityCallBack,&proxyReachabilityContext)){
        NSLog(@"Cannot register reachability cb");
    };
    
    if(!SCNetworkReachabilityScheduleWithRunLoop(proxyReachability, main_run_loop, kCFRunLoopDefaultMode)){
        NSLog(@"Cannot register schedule reachability cb");
    };
    
}

/*初始化SIP引擎*/
-(void)Init{
    
    connectivity=none;
    
    signal(SIGPIPE, SIG_IGN);
    
    if(theSipEngine == nil){
        theSipEngine = CreateSipEngine();
        
        if(theEventObserver == nil){
            theEventObserver = new SipEventObserver(self);
        }
        
        theSipEngine->RegisterSipEngineStateObserver(*theEventObserver);
        theSipEngine->EnableDebug(YES);
        
        theSipEngine->Init();
#if 0
        theSipEngine->SetNetworkReachable(true);
#endif
        [self setProxyReachability];
        
        mIterateTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1
                                                         target: self
                                                       selector: @selector(handleTimer)
                                                       userInfo: nil
                                                        repeats: YES];
        
        theSipEngine->SetCallCap(CALL_CAP_AUDIO);
        
        theSipEngine->SetAEC(NO);
        theSipEngine->SetAGC(NO);
        theSipEngine->SetNS(NO,2);
        theSipEngine->EnableMediaEncryption(NO);
        theSipEngine->SetVOE_FEC(NO);
        
        theSipEngine->SetSpeakerVolume(255);
        theSipEngine->SetMicPhoneVolume(255);
        
//        theSipEngine->SetDtmfMode(RFC2833);
        
        /*设置用户代理*/
        theSipEngine->SetUserAgent("51dyt","iOS");
        
        first_run_ = YES;
        [self setCallDelegate:nil];
        [self setRegistrationDelegate:nil];
    }
}

-(void)startVideoChannel:(int)cam_index withRemoteWnd:(void *)remote_wnd withPreviewWnd:(void *)local_wnd{
    theSipEngine->StartVideoChannel(cam_index, remote_wnd, local_wnd);
}

-(void)swapCamera:(int) cam_index withPreviewWnd:(void *)local_wnd{
    theSipEngine->ChangeCamera(cam_index, local_wnd);
}
-(void)updateCall:(bool)enable_video{
    theSipEngine->UpdateCall(enable_video);
}

-(void)stopVideoChannel{
    theSipEngine->StopVideoChannel();
}

-(void)setOrientation:(int) oritentation{
    
}

-(void)SetLoudspeakerStatus:(bool)yesno{
    if(theSipEngine!=NULL) theSipEngine->SetLoudspeakerStatus(yesno);
}

-(void)TerminateCall{
    theSipEngine->TerminateCall();
}

-(void)MuteMic:(bool)yesno{
    theSipEngine->MuteMic(yesno);
}

-(void) runNetworkConnection {
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"192.168.0.200", 15000, nil, &writeStream);
    //	CFWriteStreamOpen (writeStream);
    const char* buff="hello";
    CFWriteStreamWrite (writeStream,(const UInt8*)buff,strlen(buff));
    CFWriteStreamClose (writeStream);
}

-(void) kickOffNetworkConnection {
    /*start a new thread to avoid blocking the main ui in case of peer host failure*/
    [NSThread detachNewThreadSelector:@selector(runNetworkConnection) toTarget:self withObject:nil];
}

/*加载配置*/
-(void)LoadConfig{
    
    if(first_run_){
        
        theSipEngine->SetTransport(SIP_UDP);
        theSipEngine->SetEnCrypt(true, true);
        
        theSipEngine->SetLoudspeakerStatus(false);
        first_run_ = NO;
    }
}

-(void) Terminate{
    
    [mIterateTimer invalidate];
    
    if (theSipEngine) {
        
        theSipEngine->Terminate();
        theSipEngine->DeRegisterSipEngineStateObserver();
        
        if(theEventObserver){
            delete theEventObserver;
            theEventObserver = nil;
        }
        
        DeleteSipEngine(theSipEngine);
        theSipEngine = nil;
        
    }
    
    
    SCNetworkReachabilityUnscheduleFromRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(proxyReachability);
    proxyReachability=nil;
}

+(SipEngineManager*) instance {
    if (theSipEngineManager==nil) {
        theSipEngineManager = [[SipEngineManager alloc] init];
    }
    return theSipEngineManager;
}

- (void)stopCallRing
{
    if (theEventObserver) {
        theEventObserver->stopRing();
    }
}

+(SipEngine*) getSipEngine{
    return theSipEngine;
}

- (void)repeatScheduleNotification:(NSString*)from types:(ScheduleNotificationType)type content:(NSString*)content
{
    NSInteger typeValue = 0;
    if (type == kNotifyAudioCall) {
        typeValue = 0;
    }else if (type == kNotifyVideoCall){
        typeValue = 1;
    }else if (type == kNotifyTextMessage){
        typeValue = 2;
    }
    
    [self stopScheNotiTimer];
    
    _repeatScheCount = 0;
    _repeatScheNotiTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(doScheduleNotification:) userInfo:@{@"from" : from, @"type" : [NSNumber numberWithInteger:typeValue], @"content" : content ? content : @""} repeats:YES];
    [_repeatScheNotiTimer fire];
    
}

- (void)stopScheNotiTimer
{
    NSLog(@"关闭定时器");
    _repeatScheCount = 0;
    if (_repeatScheNotiTimer) {
        [_repeatScheNotiTimer invalidate];
        _repeatScheNotiTimer = nil;
    }
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)doScheduleNotification:(NSTimer *)timer
{
    _repeatScheCount++;
    if (_repeatScheCount > 6) {
        _repeatScheCount = 0;
        [self stopScheNotiTimer];
    }else{
        NSDictionary *userInfo = timer.userInfo;
        [self doScheduleNotification:userInfo[@"from"] types:[userInfo[@"type"] integerValue] content:userInfo[@"content"]];
    }
}

-(void)doScheduleNotification:(NSString*)from types:(NSInteger)type content:(NSString*)content
{
    UILocalNotification* alarm = [[UILocalNotification alloc] init];
    
    UIApplication* theApp = [UIApplication sharedApplication];
    NSArray*    oldNotifications = [theApp scheduledLocalNotifications];
    
    if ([oldNotifications count] > 0)
        [theApp cancelAllLocalNotifications];
    
    NSDate *fireDate = [NSDate dateWithTimeInterval:0.1 sinceDate:[NSDate dateWithTimeIntervalSinceNow:0]];
//    NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    if (alarm)
    {
        alarm.fireDate = fireDate;
        alarm.timeZone = [NSTimeZone defaultTimeZone];
        alarm.repeatInterval = (NSCalendarUnit)0;
        NSString* alertBody = nil;
        NSString *newFrom;
        //去掉“+”
        if ([from containsString:@"+"]) {
            newFrom = [from stringByReplacingOccurrencesOfString:@"+" withString:@""];
            from = newFrom;
        }
        //去掉86
        if ([[from substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"86"]) {
            newFrom = [from substringFromIndex:2];
            from = newFrom;
        }
        //转换成备注
        ContactModel *tempModel;
        for (ContactModel *model in [AddressBookManager shareManager].dataArr) {
            tempModel = model;
            if ([model.phoneNumber containsString:@"-"]) {
                tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
            }
            if ([model.phoneNumber containsString:@" "]) {
                tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
            }
            if ([model.phoneNumber containsString:@"+86"]) {
                tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"+86" withString:@""];
            }
            if ([from isEqualToString:[NSString stringWithFormat:@"%@", tempModel.phoneNumber]]) {
                newFrom = tempModel.name;
                from = newFrom;
            }
            if ([from isEqualToString:@"anonymous"]) {
                from = @"未知";
            }
        }
        
        if (type == 0) {
            //incoming call
//            alertBody =[NSString  stringWithFormat:@"%@ %@", NSLocalizedString(@"Incoming Call",@""),from];
            alertBody =[NSString  stringWithFormat:@"%@ %@", NSLocalizedString(@"新来电",@""),from];
            alarm.alertAction = NSLocalizedString(@"Answer",@"");
        } else if (type == 1){
            alertBody =[NSString  stringWithFormat:NSLocalizedString(@"Incoming Video Call %@",@""),from];
            alarm.alertAction = NSLocalizedString(@"Answer",@"");
        }
        alarm.alertBody = alertBody;
        if (kSystemVersionValue >= 10.0 && isUseCallKit) {
            
        }else{
            alarm.soundName = @"appleCallComing.wav";
        }
//        alarm.soundName = @"appleCallComing.wav";
        alarm.hasAction = YES;
//        alarm.soundName = @"default.wav";
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInteger:type],    @"type",
                              from,                             @"from",
                              nil];
        [alarm setUserInfo:dict];
        [theApp scheduleLocalNotification:alarm];
    }
}

-(void)sound{
    SystemSoundID soundID;
    //NSBundle来返回音频文件路径
    NSString *soundFile = [[NSBundle mainBundle] pathForResource:@"voip_call" ofType:@"mp3"];
    //建立SystemSoundID对象，但是这里要传地址(加&符号)。 第一个参数需要一个CFURLRef类型的url参数，要新建一个NSString来做桥接转换(bridge)，而这个NSString的值，就是上面的音频文件路径
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundFile], &soundID);
    //播放提示音 带震动
    AudioServicesPlayAlertSound(soundID);
    //播放系统声音
    //    AudioServicesPlaySystemSound(soundID);
}

/*线性处理事件*/
-(void)handleTimer{
    if(theSipEngine){
        theSipEngine->CoreEventProgress();
    }
}

-(void)ForceReloadConfig{
    first_run_ = YES;
    [self LoadConfig];
}

-(void) RefreshSipRegister
{
    
    theSipEngine->RefreshRegisters();
}

//**********************BG mode management*************************///////////
-(void) enterBackgroundMode {
    //进入后台模式
    
    //For registration register
    theSipEngine->RefreshRegisters();
    
    //wait for registration answer
    int i=0;
    while (!theSipEngine->AccountIsRegstered() && i++<40 ) {
        theSipEngine->CoreEventProgress();
        usleep(100000);
    }
    
    //register keepalive
    if ([[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
        NSLog(@"keepalive handler");
        
        if (theSipEngine == nil) {
            NSLog(@"It seam that BeeChat BG mode was deacticated, just skipping");
            return;
        }
        
        //kick up network cnx, just in case
        [self kickOffNetworkConnection];
        
        [self RefreshSipRegister];
        
        theSipEngine->CoreEventProgress();
    }]) {
        NSLog(@"keepalive handler succesfully registered");
    } else {
        NSLog(@"keepalive handler cannot be registered");
    }
    
}

-(void) becomeActive {
    
    if (proxyReachability){
        SCNetworkReachabilityFlags flags=0;
        if (!SCNetworkReachabilityGetFlags(proxyReachability, &flags)) {
            NSLog(@"Cannot get reachability flags, re-creating reachability context.");
            [self setProxyReachability];
        }else{
            networkReachabilityCallBack(proxyReachability, flags,(__bridge void *)self);
            if (flags==0){
                /*workaround iOS bug: reachability API cease to work after some time.*/
                /*when flags==0, either we have no network, or the reachability object lies. To workaround, create a new one*/
                [self setProxyReachability];
            }
        }
    }else NSLog(@"No proxy reachability context created !");
    
    [self RefreshSipRegister];
}

@end
