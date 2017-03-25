#import "SipEngineEventObserver.h"
#import "SipEngineManager.h"


SipEventObserver::SipEventObserver(SipEngineManager *sip_engine_manager){
	sip_engine_manager_ = sip_engine_manager;
}

SipEventObserver::~SipEventObserver(){
	
}

void SipEventObserver::OnSipEngineState(SipEngineState code){
    isStop = NO;
	NSString *msg=@"";
	if(code == EngineStarting){
		msg = @"启动SIP Engine";
	}
	if(code == EngineInitialized){
		msg = @"初始化成功";
		
	}
	if(code == EngineInitializedFailed){
		msg = @"初始化失败";
	}
	if(code == EngineTerminated){
		msg = @"成功销毁";
	}
	
	NSLog(@"%@",msg);
}

void SipEventObserver::OnRegistrationState(RegistrationState code,RegistrationErrorCode e_errno){
	NSString *msg=@"";
	if(code == 1){
		msg = @"正在注册...";
	}
	if(code == 2){
		msg = @"注册成功！";
		
	}
	if(code == 3){
		msg = @"您的账号已注销";
	}
    
	if(code == 4){
		msg = [NSString stringWithFormat:@"注册失败，错误代码 %d",e_errno];
	}
	
	NSLog(@"%@",msg);
	
	if (sip_engine_manager_) {
		if(sip_engine_manager_.registrationDelegate != nil)
			[sip_engine_manager_.registrationDelegate OnRegistrationState:code withErrorCode:e_errno];
	}
}

void SipEventObserver::OnNewCall(CallDir dir, const char *peer_caller, bool is_video_call){
	
	if (dir == CallIncoming) {
        //当系统为10.0以上时,不作操作,由系统处理
        if (kSystemVersionValue >= 10.0 && isUseCallKit) {
            
        }else{
            isStop = NO;
            if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
                && [UIApplication sharedApplication].applicationState !=  UIApplicationStateActive) {
                /*程序在后台使用通知中心提示来电*/
//                [SipEngineManager doScheduleNotification:[NSString  stringWithFormat:NSLocalizedString(@"%s",nil),peer_caller] types:is_video_call? kNotifyVideoCall : kNotifyAudioCall content:nil];
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    if (!isStop) {
//                          [SipEngineManager doScheduleNotification:[NSString  stringWithFormat:NSLocalizedString(@"%s",nil),peer_caller] types:is_video_call? kNotifyVideoCall : kNotifyAudioCall content:nil];
//                    }
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        if (!isStop) {
//                              [SipEngineManager doScheduleNotification:[NSString  stringWithFormat:NSLocalizedString(@"%s",nil),peer_caller] types:is_video_call? kNotifyVideoCall : kNotifyAudioCall content:nil];
//                        }
//                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                            if (!isStop) {
//                                [SipEngineManager doScheduleNotification:[NSString  stringWithFormat:NSLocalizedString(@"%s",nil),peer_caller] types:is_video_call? kNotifyVideoCall : kNotifyAudioCall content:nil];
//                            }
//                        });
//                    });
//                });
                [[SipEngineManager instance] repeatScheduleNotification:[NSString  stringWithFormat:NSLocalizedString(@"%s",nil),peer_caller] types:is_video_call? kNotifyVideoCall : kNotifyAudioCall content:nil];
            }else{
                /*前台模式，播放声音或震动*/
                //大于10.0通过系统调用
                startRing();
                if ([[UIDevice currentDevice].systemVersion floatValue] > 9.0) {
                    startVibrate();
                } else {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                }
                
                //            startRing();
                //            if ([[UIDevice currentDevice].systemVersion floatValue] > 9.0) {
                //                startVibrate();
                //            } else {
                //                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                //            }
                
                //            [sip_engine_manager_ sound];//iOS 10会崩溃

            }
        }
	}
    
    if (sip_engine_manager_) {
        
        if(sip_engine_manager_.callDelegate != nil)
            [sip_engine_manager_.callDelegate
             OnNewCall:dir
             withPeerCallerID:[NSString stringWithFormat:NSLocalizedString(@"%s",nil),peer_caller]
             withVideo:is_video_call];
    }
}


void SipEventObserver::startVibrate() {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, startVibrate(), NULL);
    AudioServicesPlayAlertSoundWithCompletion(kSystemSoundID_Vibrate, ^{
//        startVibrate();
        if (!isStop) {
            startVibrate();
        }
        if (isStop) {
            isStop = NO;
        }
    });
//    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

void SipEventObserver::startRing() {
    [ringPlayer stop];
    //屏幕常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    NSString *musicPath = [[NSBundle mainBundle] pathForResource:@"appleCallComing" ofType:@"wav"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:musicPath];
    ringPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [ringPlayer setVolume:1];
    ringPlayer.numberOfLoops = -1; //设置音乐播放次数  -1为一直循环
    if([ringPlayer prepareToPlay])
    {
        [ringPlayer play]; //播放
    }
}

void SipEventObserver::stopRing()
{
    [ringPlayer stop];
    //关闭屏幕常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
    isStop = YES;
}

void SipEventObserver::OnCallProcessing(){
	if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate OnCallProcessing];
	}
}


void SipEventObserver::OnCallRinging(bool has_early_media){
	if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate OnCallRinging];
	}
}

void SipEventObserver::OnCallConnected(){
     	if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate OnCallConnected];
	}
}

void SipEventObserver::OnCallMediaStreamConnected(MediaTransMode mode){
    stopRing();
    if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate OnCallMediaStreamsConnected:mode];
	}
    
}

void SipEventObserver::OnCallStreamsRunning(bool is_video_call){
	if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate OnCallStreamsRunning:is_video_call];
	}
}


void SipEventObserver::OnCallPaused(){
	if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate OnCallPaused];
	}
}

void SipEventObserver::OnCallResuming(){
	if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate OnCallResume];
	}
}

void SipEventObserver::OnCallPausedByRemote(){
    if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate onCallPausedByRemote];
	}
}

void SipEventObserver::OnCallResumingByRemote(){
	if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate onCallResumeByRemote];
	}
}

void SipEventObserver::OnCallEnded(){
    if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate OnCallEnded];
        stopRing();
	}
    
    [SipEngineManager getSipEngine]->SetCallCap(CALL_CAP_AUDIO);
    
    if ([UIApplication sharedApplication].applicationState !=  UIApplicationStateActive) {
		// cancel local notif if needed
        NSLog(@"取消全部通知");
		[[UIApplication sharedApplication] cancelAllLocalNotifications];
	}
}


void SipEventObserver::OnCallFailed(CallErrorCode status){

    [SipEngineManager getSipEngine]->SetCallCap(CALL_CAP_AUDIO);
    
	NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Call failed，Error code %d",@""),status];
	NSLog(@"%@",msg);
	
	if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate OnCallFailed:status];
	}

    if ([UIApplication sharedApplication].applicationState !=  UIApplicationStateActive) {
        if (_repeatTimer) {
            [_repeatTimer invalidate];
            _repeatTimer = nil;
        }
		// cancel local notif if needed
		[[UIApplication sharedApplication] cancelAllLocalNotifications];
	}
}


void SipEventObserver::OnNetworkQuality(int ms,const char *unused){
	
	if (sip_engine_manager_) {
		if(sip_engine_manager_.callDelegate != nil)
			[sip_engine_manager_.callDelegate OnNetworkQuality:ms];
	}
}

void SipEventObserver::OnRemoteDtmfClicked(int dtmf){
	/*无需处理*/
}

void SipEventObserver::OnCallReport(CallReport *cdr){
	if (sip_engine_manager_) {
        if (sip_engine_manager_.callDelegate != nil) {
            [sip_engine_manager_.callDelegate OnCallReport:cdr];
        }
    }
}

void SipEventObserver::OnDebugMessage(int level, const char *message){
	NSLog(@"SipEngine | [%d] %s",level,message);
}
