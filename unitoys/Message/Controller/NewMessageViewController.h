//
//  NewMessageViewController.h
//  unitoys
//
//  Created by sumars on 16/11/9.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"
#import "ContactsViewController.h"
#import "KTAutoHeightTextView.h"
#import "NotifyTextField.h"

@interface NewMessageViewController : BaseViewController<PhoneNumberSelectDelegate,UITextViewDelegate,NotifyTextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *bottomInputView;
@property (weak, nonatomic) IBOutlet UIView *topEditMessageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topEditMessageViewHeight;

//输入联系人号码
@property (weak, nonatomic) IBOutlet NotifyTextField *txtLinkman;

@property (weak, nonatomic) IBOutlet KTAutoHeightTextView *txtSendText;
@property (weak, nonatomic) IBOutlet UIButton *btnSend;


- (IBAction)addLinkman:(id)sender;
- (IBAction)sendMessage:(id)sender;

//- (IBAction)editedLinkman:(id)sender;
//- (IBAction)beginEditLinkman:(id)sender;


@end
