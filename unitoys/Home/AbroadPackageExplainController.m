//
//  AbroadPackageExplainController.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "AbroadPackageExplainController.h"
#import "BrowserViewController.h"
#import "AbroadExplainController.h"
#import "AbroadPackageExplainCell.h"

#import "HTTPServer.h"
#import "BlueToothDataManager.h"
#import "UNDataTools.h"
#import "ExplainDetailsChildController.h"

@interface AbroadPackageExplainController ()

@property (nonatomic, copy) NSArray *titlesArray;

@property (nonatomic, strong) HTTPServer *localHttpServer;//本地服务器
@end

@implementation AbroadPackageExplainController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
}

- (void)initData
{
    self.title = INTERNATIONALSTRING(@"境外套餐教程");
    self.titlesArray = @[
                         @{
                             @"cellImage" : @"set_beforesetout",
                             @"cellTitle" :INTERNATIONALSTRING(@"出境前激活套餐"),
                             @"cellAction" : @"activationAction",
                             },
                         @{
                             @"cellImage" : @"set_isout",
                             @"cellTitle" :INTERNATIONALSTRING(@"在境外使用"),
                             @"cellAction" : @"userAction",
                             },
                         @{
                             @"cellImage" : @"set_isback",
                             @"cellTitle" :INTERNATIONALSTRING(@"回国后恢复设置"),
                             @"cellAction" : @"recoveryAction",
                             },
                         ];
    
    self.tableView.rowHeight = 50;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerNib:[UINib nibWithNibName:@"AbroadPackageExplainCell" bundle:nil] forCellReuseIdentifier:@"AbroadPackageExplainCell"];
}

- (void)initExplainDetailsData
{
    [self performSelector:@selector(configLocalHttpServer) withObject:nil afterDelay:1];
    [self initDetailsData];
    [self pushDetailsVc];
}
- (void)initDetailsData
{
    NSMutableArray *dataArray = [NSMutableArray array];
    NSDictionary *page1 = @{
                            @"nameTitle" : INTERNATIONALSTRING(@"插电话卡"),
                            @"detailTitle" : INTERNATIONALSTRING(@"将爱小器国际卡插入手机中,然后将您的国内电话卡插入到手环或双待王中"),
                            @"explainImage" : @"pic_cdhk",
                            @"pageType" : @(1),
                            };
    
    NSDictionary *page2 = @{
                            @"nameTitle" : INTERNATIONALSTRING(@"安装APN"),
                            @"detailTitle" : INTERNATIONALSTRING(@"点击按钮会跳转到系统设置,点击右上角\"安装\"按钮后,输入验证码同意安装"),
                            @"explainImage" : @"ios_apn",
                            @"buttonTitle" : INTERNATIONALSTRING(@"安装APN"),
                            @"buttonAction" : @"apnSettingAction",
                            @"pageType" : @(1),
                            };
    
    NSString *page3Title;
    NSString *page3ImageStr;
    if (self.isSupport4G) {
        page3Title = INTERNATIONALSTRING(@"点击按钮会跳转到系统设置，点击\"蜂窝移动网络数据选项\"然后开启数据漫游,开启4G网络(或选择4G网络)");
        page3ImageStr = @"pic_ios_open_sj";
    }else{
        page3Title = INTERNATIONALSTRING(@"点击按钮会跳转到系统设置，点击\"蜂窝移动网络数据选项\"然后开启数据漫游,关闭4G网络(或选择3G网络)");
        page3ImageStr = @"pic_ios_sj";
    }
    NSDictionary *page3 = @{
                            @"nameTitle" : INTERNATIONALSTRING(@"修改移动网络设置"),
                            @"detailTitle" : page3Title,
                            @"explainImage" : page3ImageStr,
                            @"buttonTitle" : INTERNATIONALSTRING(@"移动网络设置"),
                            @"buttonAction" : @"gotoSystemSettingAction",
                            @"pageType" : @(1),
                            };
    
    NSDictionary *page4 = @{
//                            @"nameTitle" : INTERNATIONALSTRING(@"接打电话，收发短信"),
                            @"detailTitle" : INTERNATIONALSTRING(@"激活套餐后,在境外按以上步骤操作完成后,重启APP,即可免国际漫游在境外上网.接打电话,收发短信"),
                            @"pageType" : @(2),
                            };
    //根据类型确定需要添加的页面
    [dataArray addObject:page1];
    if (self.isApn) {
        [dataArray addObject:page2];
    }
    [dataArray addObject:page3];
    [dataArray addObject:page4];
    if ([UNDataTools sharedInstance].totalStep < dataArray.count - 1) {
        [UNDataTools sharedInstance].totalStep = dataArray.count - 1;
        [UNDataTools sharedInstance].currentAbroadStep = 0;
    }
    [UNDataTools sharedInstance].pagesData = dataArray;
}

- (void)pushDetailsVc
{
    ExplainDetailsChildController *detailsVc = [[ExplainDetailsChildController alloc] init];
    detailsVc.rootClassName = NSStringFromClass([self class]);
    detailsVc.apnName = self.apnName;
    detailsVc.currentPage = 0;
    detailsVc.totalPage = [UNDataTools sharedInstance].pagesData.count - 1;
    [self.navigationController pushViewController:detailsVc animated:YES];
}
#pragma mark - 本地服务器
#pragma mark - 搭建本地服务器 并且启动
- (void)configLocalHttpServer{
    if (_localHttpServer) {
        [self startServer];
        return;
    }
    _localHttpServer = [[HTTPServer alloc] init];
    [_localHttpServer setType:@"_http.tcp"];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSLog(@"文件目录 -- %@",webPath);
    
    if (![fileManager fileExistsAtPath:webPath]){
        NSLog(@"File path error!");
    }else{
        NSString *webLocalPath = webPath;
        [_localHttpServer setDocumentRoot:webLocalPath];
        NSLog(@"webLocalPath:%@",webLocalPath);
        [self startServer];
    }
}
- (void)startServer {
    NSError *error;
    if([_localHttpServer start:&error]){
        NSLog(@"Started HTTP Server on port %hu", [_localHttpServer listeningPort]);
        [BlueToothDataManager shareManager].localServicePort = [NSString stringWithFormat:@"%d",[_localHttpServer listeningPort]];
    } else {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.titlesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AbroadPackageExplainCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AbroadPackageExplainCell"];
    cell.nameLabel.text = self.titlesArray[indexPath.row][@"cellTitle"];
    cell.iconImageView.image = [UIImage imageNamed:self.titlesArray[indexPath.row][@"cellImage"]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSString *actionStr = self.titlesArray[indexPath.row][@"cellAction"];
    SEL action = NSSelectorFromString(actionStr);
    if ([self respondsToSelector:action]) {
        [self performSelector:action];
    }
}

- (void)activationAction
{
    NSLog(@"activationAction");
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    BrowserViewController *browserViewController = [mainStory instantiateViewControllerWithIdentifier:@"browserViewController"];
    if (browserViewController) {
        browserViewController.loadUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"beforeGoingAbroadTutorialUrl"];
        browserViewController.titleStr = INTERNATIONALSTRING(@"激活境外套餐教程");
        [self.navigationController pushViewController:browserViewController animated:YES];
    }
}

- (void)userAction
{
    NSLog(@"userAction");
//    AbroadExplainController *abroadVc = [[AbroadExplainController alloc] init];
//    abroadVc.currentExplainType = ExplainTypeAbroad;
//    abroadVc.isSupport4G = self.isSupport4G;
//    abroadVc.isApn = self.isApn;
//    abroadVc.apnName = self.apnName;
//    [self.navigationController pushViewController:abroadVc animated:YES];
    [self initExplainDetailsData];
}

- (void)recoveryAction
{
    NSLog(@"recoveryAction");
    AbroadExplainController *abroadVc = [[AbroadExplainController alloc] init];
    abroadVc.currentExplainType = ExplainTypeInternal;
    abroadVc.isSupport4G = self.isSupport4G;
    abroadVc.isApn = self.isApn;
    abroadVc.apnName = self.apnName;
    [self.navigationController pushViewController:abroadVc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [_localHttpServer stop];
    _localHttpServer = nil;
}


@end
