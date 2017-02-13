#ifndef SIP_ENGINE_COMMON_TYPES_H
#define SIP_ENGINE_COMMON_TYPES_H

#ifdef SIP_ENGINE_EXPORT
#define SIP_ENGINE_DLLEXPORT _declspec(dllexport)
#elif SIP_ENGINE_DLL
#define SIP_ENGINE_DLLEXPORT _declspec(dllimport)
#elif defined(ANDROID) || defined(MAC_IPHONE)
#define SIP_ENGINE_DLLEXPORT __attribute__ ((visibility("default")))
#else
#define SIP_ENGINE_DLLEXPORT extern
#endif

#ifndef WIN32
#include <stdint.h>
#define __int64 int64_t
#endif

#define CALL_CAP_AUDIO	(1)
#define CALL_CAP_VIDEO	(1<<1)
#define CALL_CAP_DATA	(1<<2)

typedef enum {
    ICE_MODE_P2P = 0,
    ICE_MODE_TURN,
} IceMode;

typedef enum {
    TRANS_RTP = 0,
    TRANS_ICE
} MediaTransMode;

enum TraceLevel
{
    kTraceNone               = 0x0000,    // no trace
    kTraceStateInfo          = 0x0001,
    kTraceWarning            = 0x0002,
    kTraceError              = 0x0004,
    kTraceCritical           = 0x0008,
    kTraceApiCall            = 0x0010,
    kTraceDefault            = 0x00ff,
    
    kTraceModuleCall         = 0x0020,
    kTraceMemory             = 0x0100,   // memory info
    kTraceTimer              = 0x0200,   // timing info
    kTraceStream             = 0x0400,   // "continuous" stream of data
    
    // used for debug purposes
    kTraceDebug              = 0x0800,  // debug
    kTraceInfo               = 0x1000,  // debug info
    
    kTraceAll                = 0xffff
};

// External Trace API
class TraceCallback
{
public:
    virtual void Print(const TraceLevel level,
                       const char *traceString,
                       const int length) = 0;
protected:
    virtual ~TraceCallback() {}
    TraceCallback() {}
};


typedef enum _VideoSize
{
    UNDEFINED,
    SQCIF,     // 128*96       = 12 288
    QQVGA,     // 160*120      = 19 200
    QCIF,      // 176*144      = 25 344
    CGA,       // 320*200      = 64 000
    QVGA,      // 320*240      = 76 800
    SIF,       // 352*240      = 84 480
    WQVGA,     // 400*240      = 96 000
    CIF,       // 352*288      = 101 376
    W288P,     // 512*288      = 147 456 (WCIF)
    W368P,     // 640*368      = 235 520
    S_448P,      // 576*448      = 281 088
    VGA,       // 640*480      = 307 200
    S_432P,      // 720*432      = 311 040
    W432P,     // 768*432      = 331 776 (a.k.a WVGA 16:9)
    S_4SIF,      // 704*480      = 337 920
    W448P,     // 768*448      = 344 064
    NTSC,		// 720*480      = 345 600
    FW448P,    // 800*448      = 358 400
    S_768x480P,  // 768*480      = 368 640 (a.k.a WVGA 16:10)
    WVGA,      // 800*480      = 384 000
    S_4CIF,      // 704576      = 405 504
    SVGA,      // 800*600      = 480 000
    W544P,     // 960*544      = 522 240
    W576P,     // 1024*576     = 589 824 (W4CIF)
    HD,        // 960*720      = 691 200
    XGA,       // 1024*768     = 786 432
    WHD,       // 1280*720     = 921 600
    FULL_HD,   // 1440*1080    = 1 555 200
    UXGA,      // 1600*1200    = 1 920 000
    WFULL_HD,  // 1920*1080    = 2 073 600
    NUMBER_OF_VIDEO_SIZE
}VideoSize;

typedef enum _VideoMode{
    AUDIO_ONLY,
    VIDEO_SEND,
    VIDEO_RECV,
    VIDEO_SEND_RECV
}VideoMode;

typedef enum _transport_type{
    SIP_UDP,
    SIP_TCP,
    SIP_TLS,
    SIP_DTLS
}transport_type;

typedef enum _code_type{
    AUDIO_CODEC,
    VIDEO_CODEC
}code_type;

typedef struct AVCodecInst
{
    int pltype;
    char plname[32];
    int plfreq;
    int channels;
    int bitrate;
    code_type type;
    bool enabled;
}AVCodecInst;

typedef struct CallStatistics // 网络状态
{
    unsigned short fractionLost;
    unsigned int cumulativeLost;
    unsigned int extendedMax;
    unsigned int jitterSamples;
    int rttMs;
    int bytesSent;
    int packetsSent;
    int bytesReceived;
    int packetsReceived;
    
}CallStatistics;


typedef enum _CallDir {
    CallOutgoing, /**< outgoing call*/
    CallIncoming  /**< incoming call*/
}CallDir;

typedef enum _DtmfMode{
    RFC2833,
    INFO,
    RFC2833ANDINFO
}DtmfMode;

typedef enum _RegistrationErrorCode{
    RegNoResponse = 0,
    RegAuthOk = 200,
    RegUnauthorized = 401,
    RegForbidden = 403,
    RegNotFound = 404,
    RegProxyAuthenticationRequired = 407,
    RegNotacceptable = 606,
    RegAuthNone=100,
    RegUnAuthOk=99,
    RegNetworkUnreachable=-1,
}RegistrationErrorCode;

typedef enum _RegistrationState{
    RegistrationNone,
    RegistrationProgress,
    RegistrationOk,
    RegistrationCleared,
    RegistrationFailed
}RegistrationState;

typedef enum _SipEngineState{
    EngineStarting,
    EngineInitialized,
    EngineInitializedFailed,
    EngineTerminated
}SipEngineState;

typedef enum _CallStatus {
    CallSuccess, /**< The call was sucessful*/
    CallAborted, /**< The call was aborted */
    CallMissed, /**< The call was missed (unanswered)*/
    CallDeclined /**< The call was declined, either locally or by remote end*/
} CallStatus;


typedef enum _ProtectionModes{
    kProtectionNone,
    kProtectionFEC,
    kProtectionNACK,
    kProtectionFECNACK
} ProtectionModes;


typedef enum _CallErrorCode{
    None = 0,
    CouldNotCall,/*无法创建呼叫*/
    
    /*SIP 呼叫错误代码*/
    Unauthorized = 401,
    BadRequest = 400,
    PaymentRequired = 402,
    Forbidden = 403,
    MethodNotAllowed = 405,
    ProxyAuthenticationRequired = 407,
    RequestTimeout = 408,
    NotFound = 404,
    UnsupportedMediaType  = 415,
    BusyHere = 486,
    TemporarilyUnavailable = 480,
    RequestTerminated = 487,
    ServerInternalError = 500,
    DoNotDisturb = 600,
    Declined = 603,
}CallErrorCode;

#ifdef WIN32
typedef __int64 timestamp_t;
#else
typedef long long timestamp_t;
#endif // WIN32

typedef enum _RecordFmt{
    DATE_ID,
    ID_DATE
}RecordFmt;

typedef struct _CallReport{
    char calling[128];
    char called[128];
    CallStatus status;
    CallDir dir;
    int duration;
    bool is_video_call;
    char start_date[32];
    char record_file[2048];
    void *user_ptr;
}CallReport;

/* 状态回调*/
class SipEngineStateObserver{
    
public:/*引擎状态回调*/
    virtual void OnSipEngineState(SipEngineState code) = 0;
    
public:/*注册事件回调*/
    virtual void OnRegistrationState(RegistrationState code,RegistrationErrorCode e_errno) = 0;
    
public:/*通话事件回调*/
    virtual void OnNewCall(CallDir dir, const char *peer_caller, bool is_video_call) = 0;
    virtual void OnP2PChannelConnected(bool relay_mode, const char *local_addr,int local_port,int local_port2, const char *remote_addr,int remote_port,int remote_port2) = 0;
    virtual void OnCallProcessing() = 0;
    virtual void OnCallRinging(bool has_early_media) = 0;
    virtual void OnCallConnected() = 0;
    virtual void OnCallStreamsRunning(bool video_call) = 0;
    virtual void OnCallMediaStreamConnected(MediaTransMode mode)=0;
    virtual void OnCallPaused() = 0;
    virtual void OnCallPausedByRemote() = 0;
    virtual void OnCallResuming() = 0;
    virtual void OnCallResumingByRemote() = 0;
    virtual void OnCallEnded() = 0;
    virtual void OnCallFailed(CallErrorCode status) = 0;
    
public:
    /*被叫收到视频请求*/
    virtual void OnCallReceivedUpdateRequest(bool has_video) = 0;
    /*主叫发起视频请求被拒绝*/
    virtual void OnCallUpdated(bool has_video) = 0;
    
    /*本地摄像头切换事件*/
    virtual void OnLocalCameraBeginChange(int camera_index) = 0;
    virtual void OnLocalCameraChanged(int camera_index) = 0;
    /*远端摄像头切换事件*/
    virtual void OnRemoteCameraBeginChange(int camera_index) = 0;
    virtual void OnRemoteCameraChanged(int camera_index) = 0;
    
public:
    virtual void OnNetworkQuality(int ms, const char *vos_balance)=0;
    
public:
    virtual void OnRemoteDtmfClicked(int dtmf) = 0;
    
public:/*话单汇报*/
    virtual void OnCallReport(CallReport *cdr) = 0;
    
public:/*调试输出*/
    virtual void OnDebugMessage(int level, const char *message) = 0;
    
protected:
    virtual ~SipEngineStateObserver() {}
    
};


/*Data 通道*/

class DataProviderConsumer  {
    
public:
    virtual void OnConnected(int channel) = 0;
    
    virtual void OnDisconnected(int channel) = 0;
    
    virtual void OnDataReceived(int channel, const char* buf, int len) = 0;
    
protected:
    virtual ~DataProviderConsumer() {}
    
};

/*IM Presence*/

typedef enum {
    /**
     * Offline
     */
    PresenceStatusOffline,
    /**
     * Online
     */
    PresenceStatusOnline,
    /**
     * Busy
     */
    PresenceStatusBusy,
    /**
     * Be right back
     */
    PresenceStatusBeRightBack,
    /**
     * Away
     */
    PresenceStatusAway,
    /**
     * On the phone
     */
    PresenceStatusOnThePhone,
    /**
     * Out to lunch
     */
    PresenceStatusOutToLunch,
    /**
     * Do not disturb
     */
    PresenceStatusDoNotDisturb,
    /**
     * Moved in this sate, call can be redirected if an alternate contact address has been set using function linphone_core_set_presence_info()
     */
    PresenceStatusMoved,
    /**
     * Using another messaging service
     */
    PresenceStatusAltService,
    /**
     * Pending
     */
    PresenceStatusPending,
    
    PresenceStatusEnd
} OnlineStatus;

typedef enum {
    SubscribeSPWait,
    /**
     * Rejects incoming subscription request.
     */
    SubscribeSPDeny,
    /**
     * Automatically accepts a subscription request.
     */
    SubscribeSPAccept
} SubscribePolicy;



typedef enum {
    kFriendJoin=0,
    kFriendInfoUpdated,
    kFriendLeave,
} FriendStatusType;

typedef enum{
    kMessageSentOk = 0,
    kMessageSentOfflineStorage,
    kMessageSentFailed,
}MessageSentStatus;

class ChatSession;
/* IM 状态回调*/
class ImPresenceCallbackObserver{
    
public:
    virtual void OnNewTextMessage(ChatSession *chat, const char *message) = 0;
    virtual void OnTextMessageSendStatus(ChatSession *chat, const char *message_id, MessageSentStatus status)  = 0;
    virtual void OnTextMessageDelivered(ChatSession *chat,const char *message_id)=0;
    virtual void OnFriendStatusUpdated(const char *friend_number, FriendStatusType  status)=0;
    
protected:
    virtual ~ImPresenceCallbackObserver() {}
};

//视频状态回调用
class VideoFrameInfoObserver {
public:
    virtual void IncomingFrameSizeChanged(const int video_channel,	unsigned short width, unsigned short height) = 0;
    
    virtual void IncomingRate(const int video_channel,
                              const unsigned int framerate,
                              const unsigned int bitrate) = 0;
    
    virtual void OutgoingRate(const int video_channel,
                              const unsigned int framerate,
                              const unsigned int bitrate) = 0;
    
protected:
    virtual ~VideoFrameInfoObserver() {}
};

class  ExternalRenderer {
public:
    // This method will be called when the stream to be rendered changes in
    // resolution or number of streams mixed in the image.
    virtual int FrameSizeChange(unsigned int width,
                                unsigned int height,
                                unsigned int number_of_streams) = 0;
    
    // This method is called when a new frame should be rendered.
    virtual int DeliverFrame(unsigned char* buffer,
                             int buffer_size,
                             // RTP timestamp in 90kHz.
                             unsigned int time_stamp,
                             // Wallclock render time in miliseconds
                             __int64 render_time) = 0;
    
protected:
    virtual ~ExternalRenderer() {}
};

#endif
