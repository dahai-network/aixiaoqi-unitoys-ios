//
//  UNMessageContentController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/2.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNMessageContentController.h"

@interface UNMessageContentController ()

@property (nonatomic, strong) UIBarButtonItem *defaultLeftItem;
@property (nonatomic, strong) UIBarButtonItem *defaultRightItem;
@property (nonatomic, strong) UIBarButtonItem *editLeftItem;
@property (nonatomic, strong) UIBarButtonItem *editRightItem;

@end

@implementation UNMessageContentController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAllItems];
    [self loadNavigationBar];
}

- (void)loadNavigationBar
{
    if (self.isNewMessage) {
        self.title = @"新信息";
        self.navigationItem.rightBarButtonItem = nil;
    }else{
        self.title = @"";
        self.navigationItem.rightBarButtonItem = self.defaultRightItem;
    }
}

- (void)initAllItems
{
//    self.defaultLeftItem = self.navigationItem.leftBarButtonItem;
//    self.defaultRightItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"msg_contacts_nor"] style:UIBarButtonItemStyleDone target:self action:@selector(rightBarButtonAction)];
//    
//    self.editLeftItem = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"取消") style:UIBarButtonItemStyleDone target:self action:@selector(cancelEdit)];
//    self.editRightItem = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"全选") style:UIBarButtonItemStyleDone target:self action:@selector(selectAllCell)];
}

//- (void)selectAllCell
//{
//    if (self.selectRemoveData.count == self.messageFrames.count) {
//        //取消全选
//        [self.selectRemoveData removeAllObjects];
//        for (int i = 0; i < self.messageFrames.count; i ++) {
//            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
//            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
//        }
//    }else{
//        //全选
//        [self.selectRemoveData removeAllObjects];
//        for (int i = 0; i < self.messageFrames.count; i ++) {
//            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
//            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
//        }
//        [self.selectRemoveData addObjectsFromArray:self.messageFrames];
//    }
//}
//
//- (void)beComeEditMode
//{
//    self.bottomInputView.hidden = YES;
//    [self showEditView];
//    self.navigationItem.leftBarButtonItem = self.editLeftItem;
//    self.navigationItem.rightBarButtonItem = self.editRightItem;
//    [self.selectRemoveData removeAllObjects];
//    [self.tableView setEditing:YES animated:YES];
//}

//- (void)cancelEdit
//{
//    if (_bottomView == nil) {
//        return;
//    }
//    self.bottomInputView.hidden = NO;
//    [self hideEditView];
//    self.navigationItem.leftBarButtonItem = self.defaultLeftItem;
//    self.navigationItem.rightBarButtonItem = self.defaultRightItem;
//    [self.selectRemoveData removeAllObjects];
//    [self.tableView setEditing:NO animated:YES];
//}
//
//- (void)deleteSelectSMS
//{
//    if (self.selectRemoveData.count) {
//        NSLog(@"删除多条短信---%@", self.selectRemoveData);
//        NSMutableArray *smsArray = [NSMutableArray array];
//        for (MJMessageFrame *messageFrame in self.selectRemoveData) {
//            [smsArray addObject:messageFrame.message.SMSID];
//        }
//        [self deleteMessageSWithDatas:[self.selectRemoveData copy] SMSIds:[smsArray copy]];
//        
//        [self cancelEdit];
//    }
//}

//- (void)showEditView
//{
//    [self bottomView];
//    [UIView animateWithDuration:0.3 animations:^{
//        self.bottomView.un_top = self.view.un_height - self.bottomView.un_height;
//    }];
//}
//
//- (void)hideEditView
//{
//    [UIView animateWithDuration:0.3 animations:^{
//        self.bottomView.un_top = self.view.un_height;
//    } completion:^(BOOL finished) {
//        if (finished) {
//            [_bottomView removeFromSuperview];
//            _bottomView = nil;
//        }
//    }];
//}


//- (void)receiveNewSMSAction
//{
//    _messageFrames = nil;
//    [self loadMessages];
//}
//
//- (void)rightBarButtonAction
//{
//    if ([self.toTelephone containsString:@","]) {
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
//        if (!storyboard) {
//            return;
//        }
//        ContactsDetailViewController *contactsDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"contactsDetailViewController"];
//        if (!contactsDetailViewController) {
//            return;
//        }
//        kWeakSelf
//        contactsDetailViewController.contactMan = self.titleName;
//        contactsDetailViewController.phoneNumbers = self.toTelephone;
//        //不更新
//        contactsDetailViewController.contactsInfoUpdateBlock = ^(NSString *nickName, NSString *phoneNumber) {
//            if (nickName) {
//                weakSelf.title = nickName;
//            }else{
//                weakSelf.title = phoneNumber;
//            }
//            self.titleName = weakSelf.title;
//        };
//        //        contactsDetailViewController.contactModel = [self checkContactModelWithPhoneStr:self.toTelephone];
//        contactsDetailViewController.isMessagePush = YES;
//        [self.navigationController pushViewController:contactsDetailViewController animated:YES];
//    }else{
//        kWeakSelf
//        ContactsCallDetailsController *callDetailsVc = [[ContactsCallDetailsController alloc] init];
//        callDetailsVc.contactsInfoUpdateBlock = ^(NSString *nickName, NSString *phoneNumber) {
//            //            if ([phoneNumber isEqualToString:self.toTelephone]) {
//            //                if (![weakSelf.title isEqualToString:nickName]) {
//            //                    weakSelf.title = nickName;
//            //                }
//            //            }else{
//            //                weakSelf.title = self.toTelephone;
//            //            }
//            if (nickName) {
//                weakSelf.title = nickName;
//            }else{
//                weakSelf.title = phoneNumber;
//            }
//            //号码不可更改
//            //            weakSelf.toTelephone = phoneNumber;
//        };
//        callDetailsVc.contactModel = [self checkContactModelWithPhoneStr:self.toTelephone];
//        callDetailsVc.nickName = self.title;
//        callDetailsVc.phoneNumber = self.toTelephone;
//        callDetailsVc.isMessagePush = YES;
//        [self.navigationController pushViewController:callDetailsVc animated:YES];
//    }
//}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
