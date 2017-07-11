//
//  HelpViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/7/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "HelpViewController.h"
#import "BlueToothDataManager.h"
#import "HelpTableViewCell.h"

@interface HelpViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *listArr;

@end

@implementation HelpViewController

- (NSMutableArray *)listArr {
    if (!_listArr) {
        self.listArr = [NSMutableArray array];
    }
    return _listArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNIBOX]) {
        self.title = @"双待王帮助";
    } else if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNITOYS]) {
        self.title = @"手环帮助";
    } else {
        DebugUNLog(@"类型不对");
    }
    [self addData];
    self.tableView.estimatedRowHeight = 44.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    // Do any additional setup after loading the view from its nib.
}

- (void)addData {
    if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNIBOX]) {
        NSDictionary *firstDict = @{@"title":@"双待王是否有电?", @"detail":@"请先尝试按压双待王按键,如果屏幕未点亮,可将双待王连接充电器充电,以确保有电."};
        NSDictionary *secondDict = @{@"title":@"附近有其他手机之前连接过双待王?", @"detail":@"可先将该手机蓝牙关闭,然后再使用当前手机进行绑定."};
        NSDictionary *thirdDict = @{@"title":@"尝试重新启动蓝牙", @"detail":@"如果双待王有电,且手机贴近后仍无法搜索到,可以尝试重新启动手机蓝牙."};
        NSDictionary *forthDict = @{@"title":@"尝试重启手机", @"detail":@"如果重启蓝牙无效,请尝试重启手机."};
        NSArray *arr = [[NSArray alloc] initWithObjects:firstDict, secondDict, thirdDict, forthDict, nil];
        [self.listArr addObjectsFromArray:arr];
    } else if ([[BlueToothDataManager shareManager].deviceType isEqualToString:MYDEVICENAMEUNITOYS]) {
        NSDictionary *firstDict = @{@"title":@"手环是否有电?", @"detail":@"请先尝试按压手环按键,如果屏幕未点亮,可将手环连接充电器充电,以确保有电."};
        NSDictionary *secondDict = @{@"title":@"附近有其他手机之前连接过手环?", @"detail":@"可先将该手机蓝牙关闭,然后再使用当前手机进行绑定."};
        NSDictionary *thirdDict = @{@"title":@"在系统蓝牙设备中忽略手表", @"detail":@"设置路径:系统设置>蓝牙>点击右侧的'!'忽略此设备"};
        NSDictionary *forthDict = @{@"title":@"尝试重新启动蓝牙", @"detail":@"如果手环有电,且手机贴近后仍无法搜索到,可以尝试重新启动手机蓝牙."};
        NSDictionary *fifthDict = @{@"title":@"尝试重启手机", @"detail":@"如果重启蓝牙无效,请尝试重启手机."};
        NSArray *arr = [[NSArray alloc] initWithObjects:firstDict, secondDict, thirdDict, forthDict, fifthDict, nil];
        [self.listArr addObjectsFromArray:arr];
    } else {
        DebugUNLog(@"类型错误");
    }
    [self.tableView reloadData];
}

#pragma mark - tableView代理方法
#pragma mark 返回行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listArr.count;
}

#pragma mark 返回行高
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return 64;
//}

#pragma mark 返回cell内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier=@"HelpTableViewCell";
    HelpTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HelpTableViewCell"];
    if (!cell) {
        cell=[[[NSBundle mainBundle] loadNibNamed:identifier owner:nil options:nil] firstObject];
    }
    NSDictionary *info = self.listArr[indexPath.row];
    cell.title.text = info[@"title"];
    cell.detail.text = info[@"detail"];
    return cell;
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

@end
