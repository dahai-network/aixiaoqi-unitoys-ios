//
//  ReceivePhoneTimeController.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ReceivePhoneTimeController.h"
#import "CommunicateDetailTableViewCell.h"
#import "UNDatabaseTools.h"
#import "ConvenienceOrderDetailController.h"

@interface ReceivePhoneTimeController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong)NSDictionary *communicateDetailInfo;
@property (nonatomic, strong)CommunicateDetailTableViewCell *firstCell;
@property (nonatomic, strong)CommunicateDetailTableViewCell *secondCell;
@property (nonatomic, assign)int showIndex;

@end

@implementation ReceivePhoneTimeController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"套餐详情";
    self.showIndex = 1;
//    self.communicateDetailInfo = [[NSDictionary alloc] init];
    //cell高度自适应
    self.tableView.estimatedRowHeight = 44.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.allowsSelection = NO;
    [self checkCommunicateDetailById];
}

#pragma mark 根据ID查询套餐详情
- (void)checkCommunicateDetailById {
    HUDNoStop1(INTERNATIONALSTRING(@"正在加载..."))
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.packageID,@"id", nil];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@id%@", @"apiPackageByID", [self.packageID stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    [self getBasicHeader];
    [SSNetworkRequest getRequest:apiPackageByID params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            self.communicateDetailInfo = responseObj[@"data"][@"list"];
            NSLog(@"%@", self.communicateDetailInfo);
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            HUDNormal(responseObj[@"msg"])
        }
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            self.communicateDetailInfo = responseObj[@"data"][@"list"];
            [self.tableView reloadData];
        }
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark - tableView代理方法
#pragma mark 返回行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if (self.communicateDetailInfo) {
//        return 2;
//    }
    return 2;
}

#pragma mark 返回cell内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        static NSString *identifier=@"CommunicateDetailTableViewCell";
        self.firstCell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!self.firstCell) {
            self.firstCell=[[[NSBundle mainBundle] loadNibNamed:@"CommunicateDetailTableViewCell" owner:nil options:nil] firstObject];
            [self.firstCell.buyButton addTarget:self action:@selector(jumpToReceiveView) forControlEvents:UIControlEventTouchUpInside];
        }
        setImage(self.firstCell.imgCommunicatePhoto, self.communicateDetailInfo[@"LogoPic"])
//        self.firstCell.imgCommunicatePhoto.image = [UIImage imageNamed:@"icon_iphone"];
        self.firstCell.lblCommunicateName.text = self.communicateDetailInfo[@"PackageName"];
//        self.firstCell.lblCommunicateName.text = @"免费领取通话时长";
        self.firstCell.lblValidity.text = [NSString stringWithFormat:@"有效期：%@天", self.communicateDetailInfo[@"ExpireDays"]];
//        self.firstCell.lblValidity.text = @"有效期：30天";
        [self.firstCell.lblCommunicatePrice changeLabelTexeFontWithString:[NSString stringWithFormat:@"￥%@", self.communicateDetailInfo[@"Price"]]];
//        [self.firstCell.lblCommunicatePrice changeLabelTexeFontWithString:@"￥0.00"];
        if (self.isAlreadyReceive) {
            [self.firstCell.buyButton setTitle:@"已领取" forState:UIControlStateNormal];
            self.firstCell.buyButton.enabled = NO;
            self.firstCell.buyButton.backgroundColor = UIColorFromRGB(0x999999);
        }else{
            [self.firstCell.buyButton setTitle:@"领取" forState:UIControlStateNormal];
            self.firstCell.buyButton.enabled = YES;
            self.firstCell.buyButton.backgroundColor = UIColorFromRGB(0xF21F20);
        }
        
        return self.firstCell;
    } else if (indexPath.row == 1) {
        static NSString *identifier=@"ContentTableViewCell2";
        self.secondCell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!self.secondCell) {
            self.secondCell=[[NSBundle mainBundle] loadNibNamed:@"CommunicateDetailTableViewCell" owner:nil options:nil][2];
            [self.secondCell.firstButton2 addTarget:self action:@selector(changeShowData:) forControlEvents:UIControlEventTouchUpInside];
            [self.secondCell.secondButton2 addTarget:self action:@selector(changeShowData:) forControlEvents:UIControlEventTouchUpInside];
            [self.secondCell.threeButton2 addTarget:self action:@selector(changeShowData:) forControlEvents:UIControlEventTouchUpInside];
        }
        switch (self.showIndex) {
            case 1:
                self.secondCell.lblContent2.text = self.communicateDetailInfo[@"Details"];
//                self.secondCell.lblContent2.text = @"哈哈哈";
                [self.secondCell.firstButton2 setTitleColor:UIColorFromRGB(0x00a0e9) forState:UIControlStateNormal];
                self.secondCell.firstButtonView2.hidden = NO;
                [self.secondCell.secondButton2 setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
                self.secondCell.secondButtonView2.hidden = YES;
                [self.secondCell.threeButton2 setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
                self.secondCell.threeButtonView2.hidden = YES;
                break;
            case 2:
                self.secondCell.lblContent2.text = self.communicateDetailInfo[@"Features"];
//                self.secondCell.lblContent2.text = @"嘿嘿嘿";
                [self.secondCell.firstButton2 setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
                self.secondCell.firstButtonView2.hidden = YES;
                [self.secondCell.secondButton2 setTitleColor:UIColorFromRGB(0x00a0e9) forState:UIControlStateNormal];
                self.secondCell.secondButtonView2.hidden = NO;
                [self.secondCell.threeButton2 setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
                self.secondCell.threeButtonView2.hidden = YES;
                break;
            case 3:
                self.secondCell.lblContent2.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"paymentOfTerms"];
//                self.secondCell.lblContent2.text = @"呵呵呵";
                [self.secondCell.firstButton2 setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
                self.secondCell.firstButtonView2.hidden = YES;
                [self.secondCell.secondButton2 setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
                self.secondCell.secondButtonView2.hidden = YES;
                [self.secondCell.threeButton2 setTitleColor:UIColorFromRGB(0x00a0e9) forState:UIControlStateNormal];
                self.secondCell.threeButtonView2.hidden = NO;
                break;
            default:
                self.secondCell.lblContent2.text = self.communicateDetailInfo[@"Details"];
//                self.secondCell.lblContent2.text = @"哈哈哈";
                [self.secondCell.firstButton2 setTitleColor:UIColorFromRGB(0x00a0e9) forState:UIControlStateNormal];
                self.secondCell.firstButtonView2.hidden = NO;
                [self.secondCell.secondButton2 setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
                self.secondCell.secondButtonView2.hidden = YES;
                [self.secondCell.threeButton2 setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
                self.secondCell.threeButtonView2.hidden = YES;
                break;
        }
        return self.secondCell;
    } else {
        static NSString *identifier=@"ContentTableViewCell2";
        self.secondCell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!self.secondCell) {
            self.secondCell=[[NSBundle mainBundle] loadNibNamed:@"CommunicateDetailTableViewCell" owner:nil options:nil][2];
        }
        self.secondCell.lblContent2.text = self.communicateDetailInfo[@"Details"];
        return self.secondCell;
    }
}

- (void)changeShowData:(UIButton *)sender {
    switch (sender.tag) {
        case 101:
            self.showIndex = 1;
            break;
        case 102:
            self.showIndex = 2;
            break;
        case 103:
            self.showIndex = 3;
            break;
        default:
            self.showIndex = 1;
            break;
    }
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:1 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark 点击购买按钮点击事件
- (void)jumpToReceiveView {
    NSLog(@"领取");
    
    HUDNoStop1(INTERNATIONALSTRING(@"正在加载..."))
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.packageID,@"PackageID", nil];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@PackageID%@", @"apiOrderAddReceive", [self.packageID stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiOrderAddReceive params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            NSLog(@"apiOrderAddReceive--%@", responseObj);
            HUDNormal(@"领取成功")
            [self.firstCell.buyButton setTitle:@"已领取" forState:UIControlStateNormal];
            self.firstCell.buyButton.enabled = NO;
            self.firstCell.buyButton.backgroundColor = UIColorFromRGB(0x999999);
            self.isAlreadyReceive = YES;
            if (self.reloadDataWithReceivePhoneTime) {
                self.reloadDataWithReceivePhoneTime();
            }
            ConvenienceOrderDetailController *convenienceOrderVc = [[ConvenienceOrderDetailController alloc] init];
            convenienceOrderVc.orderDetailId = responseObj[@"data"][@"order"][@"OrderID"];
            [self.navigationController pushViewController:convenienceOrderVc animated:YES];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            HUDNormal(responseObj[@"msg"])
        }
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            self.communicateDetailInfo = responseObj[@"data"][@"list"];
            [self.tableView reloadData];
        }
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
