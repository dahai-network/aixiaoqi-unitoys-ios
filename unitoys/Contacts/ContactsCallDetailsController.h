//
//  ContactsCallDetailsController.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"
@class ContactModel;

typedef void(^ContactsInfoUpdateBlock)(NSString *nickName, NSString *phoneNumber);
@interface ContactsCallDetailsController : BaseViewController

@property (nonatomic, strong) ContactModel *contactModel;

@property (nonatomic, copy) ContactsInfoUpdateBlock contactsInfoUpdateBlock;

@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSString *phoneNumber;

//是否从短信界面弹出
@property (nonatomic, assign) BOOL isMessagePush;

@end
