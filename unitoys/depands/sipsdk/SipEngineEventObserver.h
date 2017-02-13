#import "common_types.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

class SipEngine;
@class SipEngineManager;

class SipEventObserver : public SipEngineStateObserver {
	
public:
	SipEventObserver(SipEngineManager *sip_engine_manager);
	~SipEventObserver();
    AVAudioPlayer *ringPlayer;
    BOOL isStop;//是否停止
	
public:/*引擎状态回调*/
	virtual void OnSipEngineState(SipEngineState code);
	
public:/*注册事件回调*/
	virtual void OnRegistrationState(RegistrationState code,RegistrationErrorCode e_errno);
	
public:/*通话事件回调*/
	virtual void OnNewCall(CallDir dir, const char *peer_caller, bool is_video_call);
	virtual void OnCallProcessing();
	virtual void OnCallRinging(bool has_early_media);
	virtual void OnCallConnected();
	virtual void OnCallStreamsRunning(bool is_video_call);
    virtual void OnCallMediaStreamConnected(MediaTransMode mode);

    
    virtual void OnCallPaused();
	virtual void OnCallPausedByRemote();
	virtual void OnCallResuming();
	virtual void OnCallResumingByRemote();
    
	virtual void OnCallEnded();
	virtual void OnCallFailed(CallErrorCode status);
    virtual void stopRing();
    virtual void startRing();//播放音乐
    virtual void startVibrate();//振动

public:
	virtual void OnNetworkQuality(int ms,const char *unused);
	
public:
	virtual void OnRemoteDtmfClicked(int dtmf);
	
public:/*话单汇报*/
	virtual void OnCallReport(CallReport *cdr);
	
public:/*调试输出*/
	virtual void OnDebugMessage(int level, const char *message);
    
    
public:
	/*±ªΩ– ’µΩ ”∆µ«Î«Û*/
	virtual void OnCallReceivedUpdateRequest(bool has_video){}
	/*÷˜Ω–∑¢∆ ”∆µ«Î«Û±ªæ‹æ¯*/
	virtual void OnCallUpdated(bool has_video){}
    
	/*±æµÿ…„œÒÕ∑«–ªª ¬º˛*/
	virtual void OnLocalCameraBeginChange(int camera_index){}
	virtual void OnLocalCameraChanged(int camera_index){}
	/*‘∂∂À…„œÒÕ∑«–ªª ¬º˛*/
	virtual void OnRemoteCameraBeginChange(int camera_index){}
	virtual void OnRemoteCameraChanged(int camera_index){}
    virtual void OnP2PChannelConnected(bool relay_mode, const char *local_addr,int local_port,int local_port2, const char *remote_addr,int remote_port,int remote_port2){}

private:
	SipEngineManager *sip_engine_manager_;
};
