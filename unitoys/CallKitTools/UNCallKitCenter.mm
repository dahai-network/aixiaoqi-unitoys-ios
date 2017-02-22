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
//@property (nonatomic, copy) UNCallKitActionNotificationBlock actionNotificationBlock;

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
    NSString *localName = @"爱小器";
    CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName:localName];
    config.supportsVideo = NO;
    config.maximumCallsPerCallGroup = 1;
    config.supportedHandleTypes = [NSSet setWithObjects:[NSNumber numberWithInteger:CXHandleTypePhoneNumber], nil];
    config.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:@"logo"]);
    self.provider = [[CXProvider alloc] initWithConfiguration:config];
//    [self.provider setDelegate:self queue:self.completionQueue ? self.completionQueue : dispatch_get_main_queue()];
    [self.provider setDelegate:self queue:dispatch_get_main_queue()];
    self.callController = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
    
//    self.actionNotificationBlock = ^(CXCallAction *action, UNCallActionType actionType){
//        
//    };
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
    callUpdate.supportsDTMF = NO;
//    callUpdate.supportsGrouping = NO;
//    callUpdate.supportsUngrouping = NO;
//    callUpdate.supportsHolding = NO;

    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    //通知系统有来电
    [self.provider reportNewIncomingCallWithUUID:callUUID update:callUpdate completion:completion];
    [self.provider reportCallWithUUID:_currentCallUUID updated:callUpdate];
    return callUUID;
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
    //    action.muted = mute;
    
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}

//扩音
- (void)hold:(BOOL)hold callUUID:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion
{
    if (!callUUID) {
        if (!_currentCallUUID) {
            return;
        }
        callUUID = _currentCallUUID;
    }
    
    if (self.isSendHeld) {
        return;
    }
    self.isSendHeld = YES;
    
    CXSetHeldCallAction *action = [[CXSetHeldCallAction alloc] initWithCallUUID:callUUID onHold: hold];
    //    action.onHold = hold;
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}

- (void)endCall:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion {
    if (!callUUID) {
        if (!_currentCallUUID) {
            return;
        }
        callUUID = _currentCallUUID;
    }
    if (self.isEndCall) {
        return;
    }
    self.isEndCall = YES;
    
    CXEndCallAction *action = [[CXEndCallAction alloc] initWithCallUUID:callUUID];
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}




//无论何种操作都需要 话务控制器 去 提交请求 给系统
-(void)requestTransaction:(CXTransaction *)transaction
{
    //    [_callController requestTransaction:transaction completion:completion];
    [_callController requestTransaction:transaction completion:^( NSError *_Nullable error){
        if (error !=nil) {
            NSLog(@"Error requesting transaction: %@", error);
        }else{
            NSLog(@"Requested transaction successfully");
        }
    }];
}


//- (NSUUID *)reportOutgoingCallWithContact:(XWContact *)contact completion:(XWCallKitCenterCompletion)completion
//{
//    CXHandle* handle=[[CXHandle alloc]initWithType:CXHandleTypePhoneNumber value:contact.phoneNumber];
//    _callUUID = [NSUUID UUID];
//    CXStartCallAction *action = [[CXStartCallAction alloc] initWithCallUUID:_callUUID handle: handle];
//    action.contactIdentifier = [contact uniqueIdentifier];
//
//    CXTransaction * transaction = [CXTransaction transactionWithActions:@[action]];
//
//    [self requestTransaction:transaction];
//    return _callUUID;
//}

- (void)updateCall:(NSUUID *)callUUID state:(UNCallState)state
{
    switch (state) {
        case UNCallStateConnecting:
            [self.provider reportOutgoingCallWithUUID:callUUID startedConnectingAtDate:nil];
            break;
        case UNCallStateConnected:
            [self.provider reportOutgoingCallWithUUID:callUUID connectedAtDate:nil];
            break;
        case UNCallStateEnded:
            [self.provider reportCallWithUUID:callUUID endedAtDate:nil reason:CXCallEndedReasonRemoteEnded];
            break;
        case UNCallStateEndedWithFailure:
            [self.provider reportCallWithUUID:callUUID endedAtDate:nil reason:CXCallEndedReasonFailed];
            break;
        case UNCallStateEndedUnanswered:
            [self.provider reportCallWithUUID:callUUID endedAtDate:nil reason:CXCallEndedReasonUnanswered];
            break;
        default:
            break;
    }
}


#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider{
    NSLog(@"providerDidReset---%s", __func__);
    //    CallAudio *audio = [CallAudio sharedCallAudio];
    //    [audio stopAudio];
    //执行停止音频操作
}

/// Called when the provider has been fully created and is ready to send actions and receive updates
//系统监听已经开始,程序创建时就会被调用
- (void)providerDidBegin:(CXProvider *)provider
{
    NSLog(@"providerDidBegin---%s", __func__);
}

/// Called whenever a new transaction should be executed. Return whether or not the transaction was handled:
///
/// - NO: the transaction was not handled indicating that the perform*CallAction methods should be called sequentially for each action in the transaction
/// - YES: the transaction was handled and the perform*CallAction methods should not be called sequentially
///
/// If the method is not implemented, NO is assumed.
- (BOOL)provider:(CXProvider *)provider executeTransaction:(CXTransaction *)transaction
{
    NSLog(@"executeTransaction---%s", __func__);
    return NO;
}

//通过系统向网络电话发起通话
- (void)provider:(CXProvider *)provider performStartCallAction:(nonnull CXStartCallAction *)action {
    NSLog(@"performStartCallAction---%s", __func__);
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, UNCallActionTypeStart);
    } //destination
    if (action.handle.value) {
        [action fulfill];
    } else {
        [action fail];
    }
}

//用户点击接受通话
- (void)provider:(CXProvider *)provider performAnswerCallAction:(nonnull CXAnswerCallAction *)action {
    NSLog(@"performAnswerCallAction---%s", __func__);
//    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    NSError *err;
//    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
//    if (err) {
//        NSLog(@"error setting audio category %@",err);
//    }
//    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVoiceChat error:&err];
//    if (err) {
//        NSLog(@"error setting audio Mode %@",err);
//    }
//    double sampleRate = 44100.0;
//    [audioSession setPreferredSampleRate:sampleRate error:&err];
//    if (err) {
//        NSLog(@"Error %ld, %@",(long)err.code, err.localizedDescription);
//    }
//    
//    NSTimeInterval bufferDuration = .005;
//    [audioSession setPreferredIOBufferDuration:bufferDuration error:&err];
//    if (err) {
//        NSLog(@"Error %ld, %@",(long)err.code, err.localizedDescription);
//    }
    
    
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, UNCallActionTypeAnswer);
    }
//    self.answerAction = action;
    [action fulfill];
}

//用户挂断接听
- (void)provider:(CXProvider *)provider performEndCallAction:(nonnull CXEndCallAction *)action {
    NSLog(@"performEndCallAction---%s", __func__);
    //被对方挂断或在应用内挂断电话,可以调用此方法告诉系统挂断原因
//    [provider reportCallWithUUID:action.callUUID endedAtDate:[NSDate date] reason:CXCallEndedReasonUnanswered];
    
    if (self.isEndCall) {
        self.isEndCall = NO;
    }else{
        if (self.actionNotificationBlock) {
            self.actionNotificationBlock(action, UNCallActionTypeEnd);
        }
    }
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(nonnull CXSetHeldCallAction *)action {
    NSLog(@"performSetHeldCallAction----%s", __func__);
    //为了防止APP与系统互相操作
    if (self.isSendHeld) {
        self.isSendHeld = NO;
    }else{
        if (self.actionNotificationBlock) {
            self.actionNotificationBlock(action, UNCallActionTypeHeld);
        }
    }
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    theSipEngine->MuteSpk(action.onHold);
    [action fulfill];
}

//点击系统通话界面会触发此回调
- (void)provider:(CXProvider *)provider performSetMutedCallAction:(nonnull CXSetMutedCallAction *)action {
    NSLog(@"performSetMutedCallAction---%s", __func__);
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

//group
- (void)provider:(CXProvider *)provider performSetGroupCallAction:(CXSetGroupCallAction *)action{
    NSLog(@"performSetGroupCallAction---%s", __func__);
}

- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action{
    NSLog(@"performPlayDTMFCallAction---%s", __func__);
    
    //    if (call == nil) {
    //        [action fail];
    //    }else{
    //        if (action.digits) {
    //            NSLog(@"action.digits : %@", action.digits);
    //            [call digitsForDTMF:action.digits];
    //        }
    //        [action fulfill];
    //    }
}


/// Called when an action was not performed in time and has been inherently failed. Depending on the action, this timeout may also force the call to end. An action that has already timed out should not be fulfilled or failed by the provider delegate
//timeout to end

//超时时调用
- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action{
    NSLog(@"timedOutPerformingAction---%s", __func__);
    /// Called when an action was not performed in time and has been inherently failed. Depending on the action, this timeout may also force the call to end. An action that has already timed out should not be fulfilled or failed by the provider delegate
}



/// Called when the provider's audio session activation state changes.
//此处进行通话处理
//
- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession{
    NSLog(@"didActivateAudioSession---%s", __func__);
    //发送接通通知
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Answer"];
//    if (self.answerAction) {
//        if (self.actionNotificationBlock) {
//            self.actionNotificationBlock(self.answerAction, UNCallActionTypeAnswer);
//        }
//    }
    
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    theSipEngine->MuteMic(NO);
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession{
    NSLog(@"didDeactivateAudioSession---%s", __func__);
    
}



@end
