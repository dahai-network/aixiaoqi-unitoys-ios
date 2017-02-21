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
@interface ContactsDetailViewController ()

@end

@implementation ContactsDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lblContactMan.text = self.contactMan;
    
    [self.ivContactMan setImage:[UIImage imageNamed:self.contactHead]];
    
    self.arrNumbers = [self.phoneNumbers componentsSeparatedByString:@","];
    
    
    self.tableView.delegate = self;
    
    [self.tableView reloadData];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableViewDataSource


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrNumbers.count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactPhoneCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactPhoneCell"];
    
    cell.lblPhoneLabel.text = @"电话";
    
    cell.lblPhoneNumber.text = [self.arrNumbers objectAtIndex:indexPath.row];
    
    cell.btnCall.tag = indexPath.row;
    
    cell.btnMessage.tag = indexPath.row;
    
    if (self.bOnlySelectNumber) {
        UIView *cellView = [cell.subviews firstObject];
        for (UIView *subView in cellView.subviews) {
            if ([subView isKindOfClass:[UIButton class]]) {
                [subView setHidden:YES];
            }
        }
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate&&[self.delegate respondsToSelector:@selector(didSelectPhoneNumber:)]) {
        [self.delegate didSelectPhoneNumber:[NSString stringWithFormat:@"%@|%@",self.lblContactMan.text,[_arrNumbers objectAtIndex:indexPath.row]]];
        [self.navigationController popToViewController:self.delegate animated:YES];
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
    
    
    if (!self.callActionView){
        self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue)];
        
//        [self.view addSubview:self.callActionView];
    }
    
    
    __weak typeof(self) weakSelf = self;
    
    self.callActionView.cancelBlock = ^(){
//        weakSelf.callActionView.hidden = YES;
        [weakSelf.callActionView hideActionView];
    };
    
    self.callActionView.actionBlock = ^(NSInteger callType){
//        weakSelf.callActionView.hidden = YES;
        [weakSelf.callActionView hideActionView];
        if (callType==1) {
            //网络电话
            //电话记录，拨打电话
            if (number) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeCallAction" object:[weakSelf formatPhoneNum:number]];
            }
        }else if (callType==2){
            //手环电话
            if ([BlueToothDataManager shareManager].isRegisted) {
                if (number) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeUnitysCallAction" object:[weakSelf formatPhoneNum:number]];
                }
            } else {
                HUDNormal(@"手环内sim卡未注册或已掉线")
            }
        }
    };
    
//    self.callActionView.hidden = NO;
    [self.callActionView showActionView];
    
}

- (IBAction)deleteContact:(id)sender {
    HUDNormal(@"此功能正在开发中")
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
