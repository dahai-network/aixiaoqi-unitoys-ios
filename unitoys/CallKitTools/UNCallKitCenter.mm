//
//  UNCallKitCenter.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNCallKitCenter.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SipEngineManager.h"
#import <PushKit/PushKit.h>

@implementation CXTransaction (UnExt)

+ (CXTransaction *)transactionWithActions:(NSArray <CXAction *> *)actions {
    CXTransaction *transcation = [[CXTransaction alloc] init];
    for (CXAction *action in actions) {
        [transcation addAction:action];
    }
    return transcation;
}

@end

@implementation UNContact

@end

@interface UNCallKitCenter ()<CXProviderDelegate>

@property (nonatomic, strong) CXCallController *callController;

@property (nonatomic, assign) BOOL isSendMute;
@property (nonatomic, assign) BOOL isSendHeld;
@property (nonatomic, assign) BOOL isEndCall;

@property (nonatomic, strong) CXAnswerCallAction *answerAction;

@end

@implementation UNCallKitCenter

+ (UNCallKitCenter *)sharedInstance
{
    static UNCallKitCenter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nil] init];
    });
    return instance;
}

- (void)configurationCallProvider
{
    NSString *localName = INTERNATIONALSTRING(@"爱小器");
    CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName:localName];
    config.supportsVideo = NO;
    config.maximumCallsPerCallGroup = 1;
    config.supportedHandleTypes = [NSSet setWithObjects:[NSNumber numberWithInteger:CXHandleTypePhoneNumber], nil];
    config.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:@"logo_callKit"]);
    self.provider = [[CXProvider alloc] initWithConfiguration:config];
//    [self.provider setDelegate:self queue:self.completionQueue ? self.completionQueue : dispatch_get_main_queue()];
    [self.provider setDelegate:self queue:dispatch_get_main_queue()];
    self.callController = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCallingMessage:) name:@"CallingMessage" object:nil];
}

- (void)getCallingMessage :(NSNotification *)notification {
    if (notification.object) {
        NSString *notiText = notification.object;
        if([notiText isEqualToString:INTERNATIONALSTRING(@"通话结束")]){
            //关掉当前
            [self endCall:_currentCallUUID completion:^(NSError * _Nullable error) {
                UNDebugLogVerbose(@"挂断通话");
            }];
        }
    }
}


- (void)setCompletionQueue:(dispatch_queue_t)completionQueue {
    _completionQueue = completionQueue;
    if (self.provider) {
        [self.provider setDelegate:self queue:_completionQueue];
    }
}

//网络电话呼入,交给系统托管
- (NSUUID *)reportIncomingCallWithContact:(UNContact *)contact completion:(UNCallKitCenterCompletion)completion
{
    NSString * number = contact.phoneNumber;
    CXHandle* handle=[[CXHandle alloc]initWithType:CXHandleTypePhoneNumber value:number];
    NSUUID *callUUID = [NSUUID UUID];
    _currentCallUUID=callUUID;
    
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.remoteHandle = handle;
    callUpdate.localizedCallerName = contact.displayName;
    callUpdate.supportsDTMF = YES;
//    callUpdate.supportsGrouping = NO;
//    callUpdate.supportsUngrouping = NO;
//    callUpdate.supportsHolding = NO;

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    //通知系统有来电
    [self.provider reportNewIncomingCallWithUUID:callUUID update:callUpdate completion:completion];
    [self.provider reportCallWithUUID:_currentCallUUID updated:callUpdate];
    return callUUID;
}

//- (NSUUID *)reportOutgoingCallWithContact:(UNContact *)contact completion:(UNCallKitCenterCompletion)completion
//{
//    CXHandle* handle=[[CXHandle alloc]initWithType:CXHandleTypePhoneNumber value:contact.phoneNumber];
//    _currentCallUUID = [NSUUID UUID];
//    CXStartCallAction *action = [[CXStartCallAction alloc] initWithCallUUID:_callUUID handle: handle];
//    action.contactIdentifier = [contact uniqueIdentifier];
//    
//    CXTransaction * transaction = [CXTransaction transactionWithActions:@[action]];
//    
//    [self requestTransaction:transaction];
//    return _callUUID;
//}

//网络电话呼出
- (NSUUID *)startRequestCalllWithContact:(UNContact *)contact completion:(UNCallKitCenterCompletion)completion
{
    CXHandle* handle=[[CXHandle alloc]initWithType:CXHandleTypePhoneNumber value:contact.phoneNumber];
    _currentCallUUID = [NSUUID UUID];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:_currentCallUUID handle:handle];
    startCallAction.video = NO;
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[startCallAction]] completion:completion];
    return _currentCallUUID;
}


- (NSUUID *)reportOutgoingCall:(NSUUID *)callUUID startedConnectingAtDate:(NSDate*)startDate
{
    _currentCallUUID=callUUID;
    [self.provider reportOutgoingCallWithUUID:callUUID startedConnectingAtDate:startDate];
    return callUUID;
}

//静音
- (void)mute:(BOOL)mute callUUID:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion
{
    if (!callUUID) {
        if (!_currentCallUUID) {
            return;
        }
        callUUID = _currentCallUUID;
    }
    if (self.isSendMute) {
        return;
    }
    self.isSendMute = YES;
    CXSetMutedCallAction *action = [[CXSetMutedCallAction alloc] initWithCallUUID:callUUID muted:mute];
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}


- (void)hold:(BOOL)hold callUUID:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion
{
//    if (!callUUID) {
//        if (!_currentCallUUID) {
//            return;
//        }
//        callUUID = _currentCallUUID;
//    }
    
//    if (self.isSendHeld) {
//        return;
//    }
//    self.isSendHeld = YES;
    
    //此Block只更改APP按钮状态
//    CXSetHeldCallAction *action = [[CXSetHeldCallAction alloc] initWithCallUUID:callUUID onHold: hold];
//    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}

- (void)endCall:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion {
    if (!callUUID) {
        if (!_currentCallUUID) {
            return;
        }
        callUUID = _currentCallUUID;
    }
//    if (self.isEndCall) {
//        return;
//    }
    self.isEndCall = YES;
    
    CXEndCallAction *action = [[CXEndCallAction alloc] initWithCallUUID:callUUID];
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}

//无论何种操作都需要 话务控制器 去 提交请求 给系统
-(void)requestTransaction:(CXTransaction *)transaction
{
    [_callController requestTransaction:transaction completion:^( NSError *_Nullable error){
        if (error !=nil) {
            UNDebugLogVerbose(@"Error requesting transaction: %@", error);
        }else{
            UNDebugLogVerbose(@"Requested transaction successfully");
        }
    }];
}


//- (void)updateCall:(NSUUID *)callUUID state:(UNCallState)state
//{
//    switch (state) {
//        case UNCallStateConnecting:
//            [self.provider reportOutgoingCallWithUUID:callUUID startedConnectingAtDate:nil];
//            break;
//        case UNCallStateConnected:
//            [self.provider reportOutgoingCallWithUUID:callUUID connectedAtDate:nil];
//            break;
//        case UNCallStateEnded:
//            [self.provider reportCallWithUUID:callUUID endedAtDate:nil reason:CXCallEndedReasonRemoteEnded];
//            break;
//        case UNCallStateEndedWithFailure:
//            [self.provider reportCallWithUUID:callUUID endedAtDate:nil reason:CXCallEndedReasonFailed];
//            break;
//        case UNCallStateEndedUnanswered:
//            [self.provider reportCallWithUUID:callUUID endedAtDate:nil reason:CXCallEndedReasonUnanswered];
//            break;
//        default:
//            break;
//    }
//}


#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider{
    UNDebugLogVerbose(@"providerDidReset---%s", __func__);
    //执行停止音频操作
}

//系统监听已经开始,程序创建时就会被调用
- (void)providerDidBegin:(CXProvider *)provider
{
    UNDebugLogVerbose(@"providerDidBegin---%s", __func__);
}

- (BOOL)provider:(CXProvider *)provider executeTransaction:(CXTransaction *)transaction
{
    UNDebugLogVerbose(@"executeTransaction---%s", __func__);
    return NO;
}

//通过系统向网络电话发起通话
- (void)provider:(CXProvider *)provider performStartCallAction:(nonnull CXStartCallAction *)action {
    UNDebugLogVerbose(@"performStartCallAction---%s", __func__);
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, UNCallActionTypeStart);
    }
    if (action.handle.value) {
        [action fulfill];
    } else {
        [action fail];
    }
    
}

//用户点击接受通话
- (void)provider:(CXProvider *)provider performAnswerCallAction:(nonnull CXAnswerCallAction *)action {
    UNDebugLogVerbose(@"performAnswerCallAction---%s", __func__);

    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, UNCallActionTypeAnswer);
    }
    [action fulfill];
}

//用户挂断接听
- (void)provider:(CXProvider *)provider performEndCallAction:(nonnull CXEndCallAction *)action {
    UNDebugLogVerbose(@"performEndCallAction---%s", __func__);
    
    if (self.isEndCall) {
        self.isEndCall = NO;
    }else{
        if (self.actionNotificationBlock) {
            self.actionNotificationBlock(action, UNCallActionTypeEnd);
        }
    }
//    [self updateCall:action.callUUID state:UNCallStateEnded];
    [action fulfill];
}

//暂停通话
- (void)provider:(CXProvider *)provider performSetHeldCallAction:(nonnull CXSetHeldCallAction *)action {
    UNDebugLogVerbose(@"performSetHeldCallAction----%s", __func__);
//    //此Block只更改APP按钮状态
//    if (self.actionNotificationBlock) {
//        self.actionNotificationBlock(action, UNCallActionTypeHeld);
//    }
//
//    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
//    theSipEngine->MuteSpk(action.onHold);
//    [action fulfill];
}

//点击系统通话界面会触发此回调
- (void)provider:(CXProvider *)provider performSetMutedCallAction:(nonnull CXSetMutedCallAction *)action {
    UNDebugLogVerbose(@"performSetMutedCallAction---%s", __func__);
    if (self.isSendMute) {
        self.isSendMute = NO;
    }else{
        if (self.actionNotificationBlock) {
            self.actionNotificationBlock(action, UNCallActionTypeMute);
        }
    }
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    theSipEngine->MuteMic(action.muted);
    [action fulfill];
}

//群组电话
- (void)provider:(CXProvider *)provider performSetGroupCallAction:(CXSetGroupCallAction *)action{
    UNDebugLogVerbose(@"performSetGroupCallAction---%s", __func__);
}
//双频多音功能
- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action{
    UNDebugLogVerbose(@"performPlayDTMFCallAction---%@", action.digits);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallPhoneKeyBoard" object:action.digits];
}
//超时时调用
- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action{
    UNDebugLogVerbose(@"timedOutPerformingAction---%s", __func__);
}

//此处进行通话处理
- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession{
    UNDebugLogVerbose(@"didActivateAudioSession---%s", __func__);
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    theSipEngine->MuteMic(NO);
//    theSipEngine->AnswerCall();
//    theSipEngine->StopRinging();
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession{
    UNDebugLogVerbose(@"didDeactivateAudioSession---%s", __func__);
//    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
//    if(theSipEngine->InCalling())
//        theSipEngine->TerminateCall();
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
