#ifndef SIP_ENGINE_SDK_H
#define SIP_ENGINE_SDK_H

/*Type define and event handler */
#include "common_types.h"

/*Presence*/
class SipFriend{
    
public:
    virtual int EnableSubscribe(bool yesno) = 0; /*Subscribe sip peer status*/
    virtual bool SubscribeEnabled() = 0;
    
    virtual int SetSubscribePolicy(SubscribePolicy pol) = 0;
    virtual SubscribePolicy GetSubscribePolicy() = 0;
    
    virtual const char *GetFriendNumber()=0;
protected:
    virtual ~SipFriend() {}
};

/*Text Message*/
class ChatSession{
public:
    virtual int SendTextMessage(const char *msg)=0;
    virtual int SendTextMessage2(const char *message, char *message_id)=0;
    virtual const char *GetSessionID()=0;
    
    virtual void SetUserData(void *user_data)=0;
    virtual void *GetUserData()=0;
protected:
    virtual ~ChatSession() {}
};

/*Core API*/
class  SipEngine
{
public:
    virtual int Init() = 0;
    virtual int Terminate() = 0;
    virtual bool IsInitialized() = 0;
    virtual int SetUserAgent(const char*name, const char *version) = 0;
    virtual int CoreEventProgress() = 0;
    
    virtual int EnableDebug(bool yesno) = 0;
    /*Trace*/
    virtual int SetTraceLevel(TraceLevel level) = 0;
    virtual int SetTraceCallback(TraceCallback& trace_cb) = 0;
    virtual int SetTraceFile(const char* trace_file) = 0;
    
    virtual int RegisterSipEngineStateObserver(SipEngineStateObserver& observer) = 0;
    virtual int DeRegisterSipEngineStateObserver() = 0;
    
    /*Account*/
    virtual int RegisterSipAccount(const char *username, const char *password, const char *relam, const char *server) = 0;
    virtual int RegisterSipAccount(const char *username, const char *password, const char *relam, const char *server, int port, int expire = 1800) = 0;
    virtual int SetOutboundProxy(const char *proxy) = 0;
    virtual int DeRegisterSipAccount() = 0;
    virtual bool AccountIsRegstered() = 0;
    virtual int RefreshRegisters() = 0;
    virtual int ForceReRegster() = 0;
    
    /*Call*/
    virtual int MakeCall(const char *num,bool video_enabled=false) = 0;
    virtual int MakeCallAskAutoAnswer(const char *num,bool video_enabled=false) = 0;
    
    virtual int AllowAutoAnswer(bool yesno) = 0;
    
    virtual int MakeCall(const char *num,bool video_enabled=false, void *user_ptr=0) = 0;
    virtual int MakeUrlCall(const char *url,bool video_enabled=false) = 0;
    virtual int SetCallUserData(void *user_ptr) = 0;
    virtual int AnswerCall(bool video_mode=false) = 0;
    virtual int TerminateCall() = 0;
    virtual int TransferCall(const char *new_num) = 0;
    virtual int GetCallStatistics(CallStatistics &stats) = 0;
    virtual bool HaveIncomingCall()=0;
    virtual bool InCalling() = 0;
    virtual int GetCurrentCallDuration() = 0;
    virtual int SetCallCap(int cap) = 0;
    /*for caller*/
    virtual int UpdateCall(bool enabled_video) = 0;
    /*for called*/
    virtual int AcceptCallUpdate(bool video) = 0;
    virtual int SendDtmf(const char *dtmf) = 0;
    virtual int SetCallHold() = 0;
    virtual int SetCallUnHold() = 0;
    
    /*Video Display*/
    virtual int SetVideoWindowId(void *remote_hWnd, void *local_hWnd) = 0;
    
    /*Camera*/
    virtual int NumberOfCaptureDevices() = 0;
    virtual int GetCaptureDevice(int index,
                                 char* deviceNameUTF8,
                                 const unsigned int deviceNameUTF8Length,
                                 char* uniqueIdUTF8,
                                 const unsigned int uniqueIdUTF8Length) = 0;
    virtual int SetCaptureDevice(int index) = 0;
    virtual int ChangeCamera(int camera_index, void *preview_hWnd) = 0;
    virtual int StartVideoChannel(int camera_index, void *remote_hWnd, void *local_hWnd) = 0;
    virtual int StartVideoChannel(int camera_index, ::ExternalRenderer *rem_ext_render, ::ExternalRenderer *local_ext_render) = 0;
    virtual int StopVideoChannel() = 0;
    
    /*Audio Device*/
    virtual int MuteMic(bool yesno) = 0;
    virtual int MuteSpk(bool yesno) = 0;
    
    /*Network*/
    virtual int SetMTU(unsigned int mtu) = 0;
    virtual int SetTransport(transport_type tp,int local_port=0) = 0;
    virtual int ResetTransport() = 0;
    virtual int SetNetworkReachable(bool yesno) = 0;
    
    
    /*P2P Settings*/
    virtual int SetICEMode(bool yesno, IceMode mode) = 0;
    virtual int SetStunServer(const char *stun_srv) = 0;
    virtual int SetTurnConfig(const char *turn_username,
                              const char *turn_passwd,
                              const char *turn_srv,
                              bool tcp_connection) = 0;
    
    /*SRTP*/
    virtual int EnableMediaEncryption(bool yesno) = 0;
    
    /*TLS*/
    virtual int SetTLS_RootCA(const char *path) = 0;
    virtual int SetTLS_Certfile(const char *certfile) = 0;
    virtual int SetTLS_PrivateKeyfile(const char *keyfile) = 0;
    virtual int SetTLS_Use_CertBuffer(bool yesno) = 0;
    virtual int SetTLS_PrivateKey_Password(const char *password) = 0;
    
    virtual int SetTLS_PrivateKey_Password(const char *password,int len) = 0;
    virtual int SetTLS_Certbuffer(const char *cert_buffer, int len) = 0;
    virtual int SetTLS_PrivateKeyBuffer(const char *key_buffer,int len) = 0;
    
public: /*for Android*/
    virtual int SetLoudspeakerStatus(bool yesno)=0;
    virtual int GetCameraOrientation(int camera_index) = 0;
    virtual int SetMobileCameraRotation(int rotation) = 0;
    
    
public: /*Text Message API*/
    virtual int RegisterImPresenceCallbackObserver(ImPresenceCallbackObserver& im_cb) = 0;
    virtual int DeRegisterImPresenceCallbackObserver() = 0;
    virtual ChatSession *CreateChatSession(const char *peer_number)=0;
    virtual int DeleteChatSession(ChatSession *&chat_session)=0;
    virtual ChatSession *FindChatSessionByPeerName(const char *peer_name)=0;
    virtual int NumOfSChatSessions()=0;
    virtual ChatSession *GetChatSession(int idx)=0;
    
public: /*for PC*/
    virtual int SetDtmfMode(DtmfMode mode) = 0;
    virtual int StartRecordingCall(const char *path, RecordFmt fmt=DATE_ID)=0;
    virtual bool CallIsRecording()=0;
    virtual int StopRecordingCall()=0;
    virtual int SetMicPhoneVolume(int vol) = 0;
    virtual int SetSpeakerVolume(int vol) = 0;
    virtual int GetMicPhoneVolume() = 0;
    virtual int GetSpeakerVolume() = 0;
    virtual int GetMicSpeechVolume() = 0;
    virtual int GetSpkSpeechVolume() = 0;
    virtual int GetNumOfPlayoutDevices()=0;
    virtual int GetPlayoutDeviceName(int index, char strNameUTF8[128], char strGuidUTF8[128])=0;
    virtual int GetNumOfRecordingDevices()=0;
    virtual int GetRecordingDeviceName(int index, char strNameUTF8[128], char strGuidUTF8[128])=0;
    virtual int GetRecordingDeviceStatus(bool& isAvailable)=0;
    virtual int GetPlayoutDeviceStatus(bool& isAvailable)=0;
    virtual int SetRecordingDevice(int index)=0;
    virtual int SetPlayoutDevice(int index)=0;
    virtual int SetAEC(bool yesno) = 0;
    virtual int SetAGC(bool yesno) = 0;
    virtual int SetNS(bool yesno,int level) = 0;
    virtual bool GetAEC() = 0;
    virtual bool GetAGC() = 0;
    virtual bool GetNS() = 0;
    virtual int SetVOE_FEC(bool yesno) = 0;
    virtual bool GetVOE_FEC() = 0;
    virtual int SetAudioCodecs(const char *codec_list ) = 0;
    virtual int SendOptionPingTest() = 0;
    virtual int SendVOSBalanceQuery() = 0;
    virtual int StartRecordVideoFile(const char* file_name_utf8,void *local_hWnd,VideoSize visize = CIF,int bitrate=256) = 0;
    virtual int StopRecordVideoFile()=0;
    virtual int StartPlayVideoFile(const char* file_name_utf8,const bool loop = false, void *local_hWnd=0) = 0;
    virtual int StopPlayVideoFile()=0;
    virtual int RegisterVideoFrameInfoObserver(::VideoFrameInfoObserver* observer)=0;
    /*Private encryption*/
    virtual int SetEnCrypt(bool enable_sip, bool enable_rtp_rtcp) =  0;
    //virtual int SetEnCryptKey(const char *key, int len) =  0;
    virtual int SetEnCryptVOSMode(bool yesno)=0;
    virtual int SetVideoSize(VideoSize size) = 0;
    virtual int GetVideoSize(VideoSize& size) = 0;
    
public: /*Presence*/
    virtual int EnablePresencePublish(bool yesno)=0;
    virtual int PublishPresenceInfo(OnlineStatus status)=0;
    virtual OnlineStatus GetCurrentPresenceStatus() = 0;
    virtual SipFriend *AddSipFriend(const char *url, SubscribePolicy pol)=0;
    virtual int RemoveSipFriend(SipFriend *fr)=0;
    virtual SipFriend *FindSipFriendByURI(const char *uri)=0;
    virtual int NumOfSipFriends()=0;
    virtual SipFriend *GetSipFriend(int idx)=0;
    
    
public: /*For Win32 PC*/
    virtual bool StartRinging( unsigned long hInstance ,int res )=0;
    virtual bool StartRinging(const char *filename) = 0;
    virtual bool InRinging() = 0;
    virtual int StopRinging() = 0;
    virtual int SetNotfyPlayerVolume(int vol) = 0;
    virtual int NotifyPlay(unsigned long hInstance ,int res) = 0;
    virtual int NotifyPlay(const char *filename) = 0;
    virtual int NotifyPlayStop() = 0;
    
protected:
    SipEngine() {};
    virtual ~SipEngine(){};
};


#ifdef __cplusplus
extern "C" {
#endif
    
    //创建/销毁引擎
    SIP_ENGINE_DLLEXPORT SipEngine* CreateSipEngine();
    SIP_ENGINE_DLLEXPORT bool DeleteSipEngine(SipEngine*& sipEngine);
    
#ifdef __cplusplus
};
#endif

#endif
