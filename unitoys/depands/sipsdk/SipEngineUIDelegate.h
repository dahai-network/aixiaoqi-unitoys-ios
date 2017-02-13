#import <UIKit/UIKit.h>
#include "common_types.h"

/*通话状态回调*/
@protocol SipEngineUICallDelegate
/*新呼叫*/
-(void) OnNewCall:(CallDir)dir 
 withPeerCallerID:(NSString*)cid
 withVideo:(BOOL)video_call;

/*外呼正在处理*/
-(void) OnCallProcessing;
/*对方振铃*/
-(void) OnCallRinging; 
/*呼叫接通*/
-(void) OnCallStreamsRunning:(bool)is_video_call;
/*呼叫链接类型  P2P 或 rtp*/
-(void) OnCallMediaStreamsConnected:(MediaTransMode)mode;
/*呼叫接通知识*/
-(void) OnCallConnected;
/*呼叫保持*/
-(void) OnCallPaused;
-(void) OnCallResume;
-(void) onCallPausedByRemote;
-(void) onCallResumeByRemote;
/*呼叫结束*/
-(void) OnCallEnded;
/*呼叫失败，并返回错误代码，代码对应的含义，请参考common_types.h*/
-(void) OnCallFailed:(CallErrorCode) error_code;

/*网络延迟反馈*/
-(void) OnNetworkQuality:(int) ms;
/*话单*/
-(void) OnCallReport:(void*)report;
@end

/*帐号注册状态回调*/
@protocol SipEngineUIRegistrationDelegate
/*SIP 引擎的启动状态*/
-(void) OnSipEngineState:(SipEngineState)code;
/*帐号注册状态反馈, 失败返回错误代码 代码对应的含义，请参考common_types.h*/
-(void) OnRegistrationState:(RegistrationState) code
			  withErrorCode:(RegistrationErrorCode) e_errno;
@end