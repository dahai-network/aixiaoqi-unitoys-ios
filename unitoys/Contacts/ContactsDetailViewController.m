//
//  ContactsDetailViewController.m
//  unitoys
//
//  Created by sumars on 16/10/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "ContactsDetailViewController.h"
#import "ContactPhoneCell.h"
#import "MJViewController.h"
#import <AddressBook/AddressBook.h>
#import "BlueToothDataManager.h"
#import <AddressBookUI/AddressBookUI.h>
#import "ContactModel.h"
#import <ContactsUI/ContactsUI.h>
#import "ContactsCallDetailsController.h"

@interface ContactsDetailViewController ()<ABPersonViewControllerDelegate,CNContactViewControllerDelegate,ABNewPersonViewControllerDelegate>

@end

@implementation ContactsDetailViewController


- (void)viewDidLoad {
    [super viewDidLoad];    
    [self setUpNav];
    
    self.tableView.delegate = self;
    self.tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self reloadTableView];
}

- (void)setUpNav
{
    if (!self.isMessagePush) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit_info_nor"] style:UIBarButtonItemStyleDone target:self action:@selector(editContactInfo)];
    }
}

- (void)reloadTableView
{
    self.lblContactMan.text = self.contactMan;
    [self.ivContactMan setImage:[UIImage imageWithData:self.contactHead]];
    self.arrNumbers = [self.phoneNumbers componentsSeparatedByString:@","];
    [self.tableView reloadData];
}

- (void)editContactInfo
{
    if ([[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        if (self.contactModel && self.contactModel.recordRefId) {
            ABAddressBookRef addressBook = ABAddressBookCreate();
            ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(addressBook, self.contactModel.recordRefId);
            ABNewPersonViewController *personVc = [[ABNewPersonViewController alloc] init];
            personVc.newPersonViewDelegate = self;
            personVc.displayedPerson = recordRef;
            CFRelease(recordRef);
            personVc.navigationItem.title=@"简介";
            personVc.view.tag = 10;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:personVc];
            [self presentViewController:nav animated:YES completion:nil];
        }else{
            [self addContactsAction];
        }
    }else{
        if (self.contactModel && self.contactModel.contactId) {
            CNContactStore *contactStore = [[CNContactStore alloc] init];
            CNContact *contact = [contactStore unifiedContactWithIdentifier:self.contactModel.contactId keysToFetch:@[[CNContactViewController descriptorForRequiredKeys]] error:nil];
            CNContactViewController *contactVc = [CNContactViewController viewControllerForNewContact:contact];
            contactVc.view.tag = 100;
            contactVc.contactStore = contactStore;
            contactVc.allowsEditing = YES;
            contactVc.allowsActions = YES;
            contactVc.delegate = self;
            contactVc.navigationItem.title=@"简介";
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVc];
            [self presentViewController:nav animated:YES completion:nil];
        }else{
//            CNMutableContact *contact = [[CNMutableContact alloc] init];
//            contact.phoneNumbers = @[[CNLabeledValue labeledValueWithLabel:CNLabelPhoneNumberiPhone value:[CNPhoneNumber phoneNumberWithStringValue:self.phoneNumber]]];
//            CNContactViewController *contactVc = [CNContactViewController viewControllerForNewContact:nil];
//            contactVc.view.tag = 200;
//            contactVc.allowsEditing = YES;
//            contactVc.allowsActions = YES;
//            contactVc.delegate = self;
//            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVc];
//            [self presentViewController:nav animated:YES completion:nil];
            CNMutableContact *contact = [[CNMutableContact alloc] init];
            NSMutableArray *phoneArray = [NSMutableArray array];
            for (NSString *phoneNum in self.arrNumbers) {
                [phoneArray addObject:[CNLabeledValue labeledValueWithLabel:CNLabelPhoneNumberMobile value:[CNPhoneNumber phoneNumberWithStringValue:phoneNum]]];
            }
            contact.phoneNumbers = phoneArray;
            CNContactViewController *contactVc = [CNContactViewController viewControllerForNewContact:contact];
            contactVc.view.tag = 200;
            contactVc.allowsEditing = YES;
            contactVc.allowsActions = NO;
            contactVc.delegate = self;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVc];
            [self presentViewController:nav animated:YES completion:nil];
        }
    }
    
}

- (void)addContactsAction
{
    NSLog(@"添加联系人");
    CFErrorRef error = NULL;
    ABRecordRef person = ABPersonCreate ();
    ABMutableMultiValueRef multiValue = ABMultiValueCreateMutable(kABStringPropertyType);
    for (NSString *phoneNum in self.arrNumbers) {
        ABMultiValueAddValueAndLabel(multiValue, (__bridge CFTypeRef)(phoneNum), kABPersonPhoneMobileLabel, NULL);
    }
    ABRecordSetValue(person, kABPersonPhoneProperty, multiValue, &error);
    ABNewPersonViewController *newPersonVc = [[ABNewPersonViewController alloc] init];
    newPersonVc.displayedPerson = person;
    newPersonVc.newPersonViewDelegate = self;
    newPersonVc.view.tag = 20;
    CFRelease(person);
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:newPersonVc];
    [self presentViewController:nav animated:YES completion:nil];
}


#pragma mark - ABNewPersonViewControllerDelegate
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(nullable ABRecordRef)person
{
    if (person) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addressBookChanged" object:@"addressBookChanged"];
        
        NSString *name;
        NSString *phone;
        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        ABMutableMultiValueRef phoneNumRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
        NSArray *arrNumber = ((__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(phoneNumRef));
        NSString *phoneNumber = arrNumber.firstObject;
        
        if (firstName && lastName) {
            if ((phoneNumber)&&([lastName stringByAppendingString:firstName])) {
                name = [lastName stringByAppendingString:firstName];
                phone = phoneNumber;
            }
        } else if (firstName && !lastName) {
            if (phoneNumber) {
                name = firstName;
                phone = phoneNumber;
            }
        } else if (!firstName && lastName) {
            if (phoneNumber) {
                name = lastName;
                phone = phoneNumber;
            }
        } else {
            NSLog(@"9.0以前的系统，通讯录数据格式不正确");
            if (phoneNumber) {
                name = phoneNumber;
                phone = phoneNumber;
            } else {
                NSLog(@"通讯录没有号码");
            }
        }
        self.contactMan = name;
        self.phoneNumbers = phone;
        if (_contactsInfoUpdateBlock) {
            _contactsInfoUpdateBlock(name, phone);
        }
        [self reloadTableView];
    }

    [newPersonView dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - ABPersonViewControllerDelegate
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return YES;
}

#pragma mark - CNContactViewControllerDelegate
- (BOOL)contactViewController:(CNContactViewController *)viewController shouldPerformDefaultActionForContactProperty:(CNContactProperty *)property
{
    return YES;
}

- (void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(nullable CNContact *)contact
{
    NSLog(@"%@", contact);
    if (contact) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addressBookChanged" object:@"addressBookChanged"];
        
        NSString *givenName = contact.givenName;
        NSString *familyName = contact.familyName;
        NSArray *arrNumber = contact.phoneNumbers;
        NSData * thumbnailImageData;
        if (contact.thumbnailImageData) {
            thumbnailImageData = contact.thumbnailImageData;
        }else{
            UIImage *image = [UIImage imageNamed:@"default_icon"];
            thumbnailImageData = UIImagePNGRepresentation(image);
        }
        
        NSString *phoneNumber = ((CNPhoneNumber *)(contact.phoneNumbers.firstObject.value)).stringValue;
        if (arrNumber.firstObject) {
            for (CNLabeledValue *labelValue in arrNumber) {
                if (![phoneNumber containsString:[labelValue.value stringValue]]) {
                    CNPhoneNumber *number = labelValue.value;
                    phoneNumber = [phoneNumber stringByAppendingString:[NSString stringWithFormat:@",%@",number.stringValue]];
                }
            }
        }
        NSString *nickName;
        if ((phoneNumber)&&([familyName stringByAppendingString:givenName])&&![[familyName stringByAppendingString:givenName] isEqualToString:@""]) {
            nickName = [familyName stringByAppendingString:givenName];
        } else {
            NSLog(@"9.0以后的系统，通讯录数据格式不正确");
            nickName = phoneNumber;
        }
        self.contactMan = nickName;
        self.phoneNumbers = phoneNumber;
        self.contactHead = thumbnailImageData;
        [self.ivContactMan setImage:[UIImage imageWithData:thumbnailImageData]];
        self.contactModel.contactId = contact.identifier;
        if (_contactsInfoUpdateBlock) {
            _contactsInfoUpdateBlock(nickName, phoneNumber);
        }
        [self reloadTableView];
    }
    
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDataSource


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrNumbers.count;
}

//- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
//    return 1;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactPhoneCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactPhoneCell"];
//    NSString *phoneText = [NSString stringWithFormat:@"%@%@", INTERNATIONALSTRING(@"电话"), indexPath]
//    cell.textLabel.text =
    cell.lblPhoneLabel.text = [NSString stringWithFormat:@"%@%zd", INTERNATIONALSTRING(@"电话"), indexPath.row + 1];
    cell.lblPhoneNumber.text = [self.arrNumbers objectAtIndex:indexPath.row];
    
//    cell.btnCall.tag = indexPath.row;
//    
//    cell.btnMessage.tag = indexPath.row;
    
//    if (self.bOnlySelectNumber) {
//        UIView *cellView = [cell.subviews firstObject];
//        for (UIView *subView in cellView.subviews) {
//            if ([subView isKindOfClass:[UIButton class]]) {
//                [subView setHidden:YES];
//            }
//        }
//        
//    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate&&[self.delegate respondsToSelector:@selector(didSelectPhoneNumber:)]) {
        [self.delegate didSelectPhoneNumber:[NSString stringWithFormat:@"%@|%@",self.lblContactMan.text,[_arrNumbers objectAtIndex:indexPath.row]]];
        [self.navigationController popToViewController:self.delegate animated:YES];
    }else{
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        NSString *phone = [self.arrNumbers objectAtIndex:indexPath.row];
        ContactsCallDetailsController *callDetailsVc = [[ContactsCallDetailsController alloc] init];
        callDetailsVc.nickName = [self checkLinkNameWithPhoneStr:phone];
        callDetailsVc.phoneNumber = phone;
        callDetailsVc.contactsInfoUpdateBlock = ^(NSString *nickName, NSString *phoneNumber) {
            
        };
        callDetailsVc.isMessagePush = self.isMessagePush;
        [self.navigationController pushViewController:callDetailsVc animated:YES];
    }
}

- (IBAction)rewriteMessage:(id)sender {
    NSString *number = [self.arrNumbers objectAtIndex:[(UIButton *)sender tag]];
    if (number) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
        if (storyboard) {
            MJViewController *MJViewController = [storyboard instantiateViewControllerWithIdentifier:@"MJViewController"];
            if (MJViewController) {
                MJViewController.title = [self checkLinkNameWithPhoneStr:[self formatPhoneNum:number]];
                MJViewController.toTelephone = number;
                MJViewController.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:MJViewController animated:YES];
                
            }
        }
    }
    
}

- (IBAction)callPhoneNumber:(id)sender {
    NSString *number = [self.arrNumbers objectAtIndex:[(UIButton *)sender tag]];
    //手环电话
    if ([BlueToothDataManager shareManager].isRegisted) {
        if (number) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeUnitysCallAction" object:[self formatPhoneNum:number]];
        }
    } else {
        HUDNormal(INTERNATIONALSTRING(@"设备内sim卡未注册或已掉线"))
    }
    
    
//    NSString *number = [self.arrNumbers objectAtIndex:[(UIButton *)sender tag]];
//    if (!self.callActionView){
//        self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue)];
//        
////        [self.view addSubview:self.callActionView];
//    }
//    
//    
//    __weak typeof(self) weakSelf = self;
//    
//    self.callActionView.cancelBlock = ^(){
////        weakSelf.callActionView.hidden = YES;
//        [weakSelf.callActionView hideActionView];
//    };
//    
//    self.callActionView.actionBlock = ^(NSInteger callType){
////        weakSelf.callActionView.hidden = YES;
//        [weakSelf.callActionView hideActionView];
//        if (callType==1) {
//            //网络电话
//            //电话记录，拨打电话
//            if (number) {
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeCallAction" object:[weakSelf formatPhoneNum:number]];
//            }
//        }else if (callType==2){
//            //手环电话
//            if ([BlueToothDataManager shareManager].isRegisted) {
//                if (number) {
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeUnitysCallAction" object:[weakSelf formatPhoneNum:number]];
//                }
//            } else {
//                HUDNormal(INTERNATIONALSTRING(@"设备内sim卡未注册或已掉线"))
//            }
//        }
//    };
//    
////    self.callActionView.hidden = NO;
//    [self.callActionView showActionView];
    
}


- (IBAction)deleteContact:(id)sender {
    HUDNormal(INTERNATIONALSTRING(@"此功能正在开发中"))
}

- (NSString *)formatPhoneNum:(NSString *)phone
{
    phone = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([phone hasPrefix:@"86"]) {
        NSString *formatStr = [phone substringWithRange:NSMakeRange(2, [phone length]-2)];
        return formatStr;
    }
    else if ([phone hasPrefix:@"+86"])
    {
        if ([phone hasPrefix:@"+86·"]) {
            NSString *formatStr = [phone substringWithRange:NSMakeRange(4, [phone length]-4)];
            return formatStr;
        }
        else
        {
            NSString *formatStr = [phone substringWithRange:NSMakeRange(3, [phone length]-3)];
            return formatStr;
        }
    }
    return phone;
}

@end
