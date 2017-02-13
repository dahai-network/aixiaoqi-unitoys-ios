//
//  RegisterViewController.h
//  unitoys
//
//  Created by sumars on 16/9/17.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"
#import "UnderlineField.h"

@interface RegisterViewController : BaseViewController<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UnderlineField *edtPhoneNumber;
@property (weak, nonatomic) IBOutlet UnderlineField *edtVerifyCode;
@property (weak, nonatomic) IBOutlet UnderlineField *edtPassCode;

@property (weak, nonatomic) IBOutlet UIButton *btnSendVerifyCode;

@property (readwrite) BOOL bSecure;

@property (readwrite) BOOL bAggre;

@property (readwrite) BOOL bForgetMode;
@property (weak, nonatomic) IBOutlet UIButton *btnAction;

@property (weak, nonatomic) IBOutlet UIButton *btnAgreement;
@property (weak, nonatomic) IBOutlet UIButton *btnLicense;

@property (weak, nonatomic) IBOutlet UIButton *btnShowWords;

@property (readwrite) NSTimer *hintTimer;
@property (readwrite) int hintTime;

- (IBAction)switchHidden:(id)sender;
- (IBAction)sendVerifyCode:(id)sender;
- (IBAction)registerUser:(id)sender;
- (IBAction)forgetPassword:(id)sender;

- (IBAction)doAction:(id)sender;


- (IBAction)switchAgreement:(id)sender;
- (IBAction)showAgreement:(id)sender;

- (IBAction)exit:(id)sender;


@end
