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

@interface AbroadPackageExplainController ()

@property (nonatomic, copy) NSArray *titlesArray;

@end

@implementation AbroadPackageExplainController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
}

- (void)initData
{
    self.title = @"境外套餐教程";
    self.titlesArray = @[
                         @{
                             @"cellTitle" :@"出境前激活套餐",
                             @"cellAction" : @"activationAction",
                             },
                         @{
                             @"cellTitle" :@"在境外使用",
                             @"cellAction" : @"userAction",
                             },
                         @{
                             @"cellTitle" :@"回国后恢复设置",
                             @"cellAction" : @"recoveryAction",
                             },
                         ];
    
    self.tableView.rowHeight = 50;
    self.tableView.tableFooterView = [UIView new];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.titlesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"normalCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"normalCell"];
    }
    cell.textLabel.text = self.titlesArray[indexPath.row][@"cellTitle"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
        browserViewController.titleStr = @"激活境外套餐教程";
        [self.navigationController pushViewController:browserViewController animated:YES];
    }
}

- (void)userAction
{
    NSLog(@"userAction");
    AbroadExplainController *abroadVc = [[AbroadExplainController alloc] init];
    abroadVc.currentExplainType = ExplainTypeAbroad;
    abroadVc.isSupport4G = self.isSupport4G;
    abroadVc.isApn = self.isApn;
    [self.navigationController pushViewController:abroadVc animated:YES];
}

- (void)recoveryAction
{
    NSLog(@"recoveryAction");
    AbroadExplainController *abroadVc = [[AbroadExplainController alloc] init];
    abroadVc.currentExplainType = ExplainTypeInternal;
    abroadVc.isSupport4G = self.isSupport4G;
    abroadVc.isApn = self.isApn;
    [self.navigationController pushViewController:abroadVc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
