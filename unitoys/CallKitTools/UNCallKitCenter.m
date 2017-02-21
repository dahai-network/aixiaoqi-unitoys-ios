//
//  UNCallKitCenter.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNCallKitCenter.h"
#import <UIKit/UIKit.h>

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
@property (nonatomic, copy) UNCallKitActionNotificationBlock actionNotificationBlock;

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
    [self.provider setDelegate:self queue:self.completionQueue ? self.completionQueue : dispatch_get_main_queue()];
    self.callController = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
}

- (void)setCompletionQueue:(dispatch_queue_t)completionQueue {
    _completionQueue = completionQueue;
    if (self.provider) {
        [self.provider setDelegate:self queue:_completionQueue];
    }
}

- (NSUUID *)reportIncomingCallWithContact:(UNContact *)contact completion:(UNCallKitCenterCompletion)completion
{
    NSString * number = contact.phoneNumber;
    CXHandle* handle=[[CXHandle alloc]initWithType:CXHandleTypePhoneNumber value:number];
    NSUUID *callUUID = [NSUUID UUID];
    _currentCallUUID=callUUID;
    
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.remoteHandle = handle;
    callUpdate.localizedCallerName = contact.displayName;
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

//-(void)performStartCallAction
- (void)mute:(BOOL)mute callUUID:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion
{
    CXSetMutedCallAction *action = [[CXSetMutedCallAction alloc] initWithCallUUID:callUUID muted:mute];
    //    action.muted = mute;
    
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}

- (void)hold:(BOOL)hold callUUID:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion
{
    CXSetHeldCallAction *action = [[CXSetHeldCallAction alloc] initWithCallUUID: callUUID onHold: hold];
    //    action.onHold = hold;
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}

- (void)endCall:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion {
    CXEndCallAction *action = [[CXEndCallAction alloc] initWithCallUUID:callUUID];
    
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}
//DTMF
- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action{
    NSLog(@"%s", __func__);
    
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

//timeout to end
- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action{
    NSLog(@"%s", __func__);
    /// Called when an action was not performed in time and has been inherently failed. Depending on the action, this timeout may also force the call to end. An action that has already timed out should not be fulfilled or failed by the provider delegate
}
//group
- (void)provider:(CXProvider *)provider performSetGroupCallAction:(CXSetGroupCallAction *)action{
    NSLog(@"%s", __func__);
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
    NSLog(@"%s", __func__);
//    CallAudio *audio = [CallAudio sharedCallAudio];
//    [audio stopAudio];
    //执行停止音频操作
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(nonnull CXAnswerCallAction *)action {
    NSLog(@"%s", __func__);
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, UNCallActionTypeAnswer);
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(nonnull CXEndCallAction *)action {
    NSLog(@"%s", __func__);
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, UNCallActionTypeEnd);
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performStartCallAction:(nonnull CXStartCallAction *)action {
    NSLog(@"%s", __func__);
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, UNCallActionTypeStart);
    } //destination
    if (action.handle.value) {
        [action fulfill];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(nonnull CXSetMutedCallAction *)action {
    NSLog(@"%s", __func__);
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, UNCallActionTypeMute);
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(nonnull CXSetHeldCallAction *)action {
    NSLog(@"%s", __func__);
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, UNCallActionTypeHeld);
    }
    [action fulfill];
}


@end
