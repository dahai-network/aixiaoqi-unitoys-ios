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

@property (weak, nonatomic) IBOutlet NotifyTextField *txtLinkman;

@property (weak, nonatomic) IBOutlet KTAutoHeightTextView *txtSendText;
@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (nonatomic, copy) NSString *linkManTele;

- (IBAction)addLinkman:(id)sender;
- (IBAction)sendMessage:(id)sender;

- (IBAction)editedLinkman:(id)sender;
- (IBAction)beginEditLinkman:(id)sender;

@property (strong,nonatomic) NSMutableArray *arrLinkman;//短信接收人列表


@end
