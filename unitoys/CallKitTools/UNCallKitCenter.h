//
//  UNCallKitCenter.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UNCallActionType) {
    UNCallActionTypeStart,
    UNCallActionTypeEnd,
    UNCallActionTypeAnswer,
    UNCallActionTypeMute,
    UNCallActionTypeHeld
};

typedef NS_ENUM(NSInteger, UNCallState) {
    UNCallStatePending,
    UNCallStateConnecting,
    UNCallStateConnected,
    UNCallStateEnded,
    UNCallStateEndedWithFailure,
    UNCallStateEndedUnanswered
};

typedef void(^UNCallKitCenterCompletion)(NSError * _Nullable error);
typedef void(^UNCallKitActionNotificationBlock)(CXCallAction *action, UNCallActionType actionType);


@interface UNContact : NSObject

@property(nonatomic, copy) NSString *uniqueIdentifier;
@property(nonatomic, copy) NSString *displayName;
@property(nonatomic, copy) NSString *phoneNumber;

@end

@interface UNCallKitCenter : NSObject

@property (nonatomic, strong) CXProvider *provider;
@property (nonatomic, strong) dispatch_queue_t completionQueue; // Default to mainQueue
@property (nonatomic, copy) NSUUID *currentCallUUID;

+ (UNCallKitCenter *)sharedInstance;

- (void)configurationCallProvider;

- (NSUUID *)reportIncomingCallWithContact:(UNContact *)contact completion:(UNCallKitCenterCompletion)completion;

-(void)requestTransaction:(CXTransaction *)transaction;

- (void)updateCall:(NSUUID *)callUUID state:(UNCallState)state;

- (void)mute:(BOOL)mute callUUID:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion;
- (void)hold:(BOOL)hold callUUID:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion;
- (void)endCall:(NSUUID *)callUUID completion:(UNCallKitCenterCompletion)completion;

@end

NS_ASSUME_NONNULL_END
