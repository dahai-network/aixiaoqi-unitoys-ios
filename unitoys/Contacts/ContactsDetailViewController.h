//
//  ContactsDetailViewController.h
//  unitoys
//
//  Created by sumars on 16/10/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"
//#import "CallActionView.h"
@class ContactModel;

@interface ContactsDetailViewController : BaseTableController

@property (nonatomic, strong) ContactModel *contactModel;

@property (weak, nonatomic) IBOutlet UILabel *lblContactMan;
@property (weak, nonatomic) IBOutlet UIImageView *ivContactMan;

//@property (strong,nonatomic) CallActionView *callActionView;

@property (readwrite) NSString *contactMan;
@property (readwrite) NSString *phoneNumbers;

@property (readwrite) NSData *contactHead;

@property (strong,nonatomic) NSArray *arrNumbers;

@property (strong,nonatomic) id delegate;

@property (readwrite) BOOL bOnlySelectNumber; //仅用于选择号码时需要隐藏短信和拨号按钮及删除联系人
//- (IBAction)rewriteMessage:(id)sender;
//- (IBAction)callPhoneNumber:(id)sender;
//
//- (IBAction)deleteContact:(id)sender;

@end

@protocol PhoneNumberSelectDelegate <NSObject>  //号码选择协议
@optional

- (void)didSelectPhoneNumber:(NSString *)phoneNumber;

@end
