//
//  UNBaseTableViewController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/19.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNBaseTableViewController.h"
#import "UNConvertFormatTool.h"
#import <Masonry/Masonry.h>
#import "UNRefreshCircleHeader.h"

@interface UNBaseTableViewController ()
@property (nonatomic, assign) NSUInteger currentPage;
@property (nonatomic, assign) BOOL isAlreadyLoading;
@property (nonatomic, assign) RefreshStyle refreshStyle;
@end

@implementation UNBaseTableViewController

- (id)initWithUrl:(NSString *)url andParams:(NSDictionary *)paramDic
{
    if (self = [super init]) {
        _url = url;
        _paramDic = paramDic;
        _page = 1;
        _autoDownPullRefresh = YES;
        _dataSource = [NSMutableArray array];
        _loadingType = UNLoadingTypeCustom;
    }
    return self;
}

- (void)createTableViewWithStyle:(UITableViewStyle)style
{
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:style];
    [self.view addSubview:_tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
        make.width.equalTo(self.view);
        make.height.equalTo(self.view);
    }];
    [self configTableView];
}

- (void)configTableView
{
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = DefualtBackgroundColor;
    _tableView.tableFooterView = [UIView new];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    self.tableView.separatorColor = DefualtSeparatorColor;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)createRefreshWithStyle:(RefreshStyle)style
{
    _refreshStyle = style;
    if (style == RefreshStyleHead) {
        //下拉刷新
        [self createDownPullRefresh];
    }else if (style == RefreshStyleFoot){
        //上拉刷新
        [self createUpPullRefresh];
    }else if (style == RefreshStyleBoth){
        //上下拉刷新
        [self createDownPullRefresh];
        [self createUpPullRefresh];
    }
}

- (void)requestForRefresh
{
    if (_url == nil && _paramDic == nil) {
        [_tableView.mj_header endRefreshing];
        return;
    }
    _paramDic = [UNConvertFormatTool firstPageParamDictionry:_paramDic];
    [self showLoading];
    [UNNetworkManager getUrl:_url parameters:_paramDic success:^(ResponseType type, id  _Nullable responseObj) {
        [_tableView.mj_header endRefreshing];
        [self hideLoading];
        [self.dataSource removeAllObjects];
        [self requestForRefreshFinishStatu:type response:responseObj];
        if (self.tableView.mj_footer.isHidden) {
            self.tableView.mj_footer.hidden = NO;
        }
    } failure:^(NSError * _Nonnull error) {
        UNDebugLogVerbose(@"_url:%@====error:%@", _url,error);
        [_tableView.mj_header endRefreshing];
        [self hideLoadingView];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showMBMessageFailedView:@"网络或服务器异常"];
        });
    }];
}

- (void)requestForNextPage
{
    if (_url == nil && _paramDic == nil) {
        [_tableView.mj_footer endRefreshing];
        return;
    }
    _paramDic = [UNConvertFormatTool nextPageParamDictionry:_paramDic WithPage:self.page];
    [UNNetworkManager getUrl:_url parameters:_paramDic success:^(ResponseType type, id  _Nullable responseObj) {
        [_tableView.mj_footer endRefreshing];
        self.currentPage= self.page;
        [self reqeustForNextPageFinishStatu:type response:responseObj];
    } failure:^(NSError * _Nonnull error) {
        self.page = self.currentPage;
        [_tableView.mj_footer endRefreshing];
    }];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = YES;
    [self createTableViewWithStyle:UITableViewStylePlain];
    [self createRefreshWithStyle:RefreshStyleHead];
    if (self.autoDownPullRefresh) {
        [self requestForRefresh];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BaseCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BaseCell"];
    }
    cell.textLabel.text = @"111";
    return cell;
}


//下拉刷新
- (void)createDownPullRefresh
{
    self.tableView.mj_header = [UNRefreshCircleHeader headerWithRefreshingBlock:^{
        self.page = 1;
        self.currentPage = 1;
        [self.tableView.mj_footer resetNoMoreData];
        [self requestForRefresh];
    }];
}
//上拉刷新
- (void)createUpPullRefresh
{
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        if (self.tableView.mj_header.isRefreshing) {
            [self.tableView.mj_header endRefreshing];
        }
        self.page += 1;
        [self requestForNextPage];
    }];
    self.tableView.mj_footer.hidden = YES;
}


- (void)requestForRefreshFinishStatu:(ResponseType)type response:(id)responseData
{
    
}

- (void)reqeustForNextPageFinishStatu:(ResponseType)type response:(id)responseData
{

}

- (void)showLoading
{
    if ((self.refreshStyle == RefreshStyleHead || self.refreshStyle == RefreshStyleBoth) && self.isAlreadyLoading) {
        return;
    }
    
    if (self.loadingType == UNLoadingTypeCustom) {
        [self showLoadingView];
    }else{
        [self showMBLoadingView];
    }
}

- (void)hideLoading
{
    if ((self.refreshStyle == RefreshStyleHead || self.refreshStyle == RefreshStyleBoth) && self.isAlreadyLoading) {
        return;
    }
    self.isAlreadyLoading = YES;
    
    if (self.loadingType == UNLoadingTypeCustom) {
        [self hideLoadingView];
    }else{
        [self hideMBLoadingView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
