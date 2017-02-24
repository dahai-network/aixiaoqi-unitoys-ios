//
//  SipEngineManager.h
//  MicroVoice
//
//  Created by DuanWei on 11-11-29.
//  Copyright 2011  MicroVoice.co.jp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioSession.h>
#include<AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioPlayer.h>

#import <SystemConfiguration/SCNetworkReachability.h>
#import "SipEngineUIDelegate.h"
#import "SipEngineEventObserver.h"

#include "SipEngine.h"
#include "common_types.h"

typedef enum _Connectivity {
	wifi,
	wwan
	,none
} Connectivity;

#define kCallDir_Initialize 0
#define kCallDir_Calling 1
#define kCallDir_Incoming 2
#define kCallDir_OfflineCall 3
/*
 type:
 0：通话
 1：短信
 2：通话被保持
 3：呼叫中
 4：通知通话
 */
typedef enum
{
    ring_tone, 
    ring_message, 
    ring_holded,
    ring_calling, 
    ring_background_call
}
RingTones;


typedef enum ScheduleNotificationType{
    kNotifyAudioCall = 0,
    kNotifyVideoCall,
    kNotifyTextMessage,
} ScheduleNotificationType;

@interface SipEngineManager : NSObject {
    
@private
	SCNetworkReachabilityContext proxyReachabilityContext;
	SCNetworkReachabilityRef proxyReachability;
    
//    AVAudioPlayer *ringPlayer;
	NSTimer *mIterateTimer;
    
//    id<SipEngineUICallDelegate> callDelegate;
	__weak id<SipEngineUICallDelegate> callDelegate;
	__weak id<SipEngineUIRegistrationDelegate> registrationDelegate;
	
	SipEventObserver *theEventObserver;

	BOOL first_run_;
@public
	Connectivity connectivity;
}

+(SipEngineManager*) instance;
+(SipEngine*) getSipEngine;
+(void)doScheduleNotification:(NSString*)from types:(ScheduleNotificationType)type content:(NSString*)content;

-(void)Init;
-(void)LoadConfig;
-(void)runNetworkConnection;
-(void)kickOffNetworkConnection;

-(BOOL)NetworkIsReachable;
-(void)SetLoudspeakerStatus:(bool)yesno;

-(void)MuteMic:(bool)yesno;
-(void)TerminateCall;

-(void)Terminate;
-(void)sound;

-(void)enterBackgroundMode;
-(void)becomeActive;

-(void)ForceReloadConfig;

-(void)RefreshSipRegister;

@property (nonatomic, weak) id<SipEngineUICallDelegate> callDelegate;
@property (nonatomic, weak) id<SipEngineUIRegistrationDelegate> registrationDelegate;  //ARC下，代理属性修改为weak，并使用__weak修饰私有成员
@property (retain, nonatomic) NSTimer* vibrateTimer;
@property (nonatomic, assign) int resignStatue;//电话注册状态

@end
