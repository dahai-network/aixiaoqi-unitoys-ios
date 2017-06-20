//
//  UNBaseTableViewController.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/19.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNHudViewController.h"

typedef NS_ENUM(NSInteger, RefreshStyle) {
    RefreshStyleNone,    // 不创建上下拉刷新
    RefreshStyleHead,    // 只有下拉刷新
    RefreshStyleFoot,    // 只有上拉加载
    RefreshStyleBoth     // 上下拉刷新
};

typedef NS_ENUM(NSUInteger, UNLoadingType) {
    UNLoadingTypeCustom = 0, //default,自定义加载提示
    UNLoadingTypeMB = 1, //MB加载
};

@interface UNBaseTableViewController : UNHudViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView         *tableView;
@property (nonatomic, strong) NSMutableArray      *dataSource;

@property (nonatomic, copy) NSString     *url;       // 接口
@property (nonatomic, copy) NSDictionary *paramDic;  // 参数
@property (nonatomic, assign) NSUInteger page;   // 分页,每次请求前修改并传入该值(请求失败会重置为上一次的值)
@property (nonatomic, readonly) NSUInteger currentPage;  // 当前分页,只有当请求成功才会修改该值,实际以此为准
@property (nonatomic, assign) BOOL autoDownPullRefresh; // 进入页面是否自动下拉刷新,默认YES
@property (nonatomic, assign) UNLoadingType loadingType;

@property (nonatomic, readonly) RefreshStyle refreshStyle;

/**
 *  初始化
 *
 *  @param url      请求的接口
 *  @param paramDic 请求的参数
 *
 *  @return return value description
 */
- (id)initWithUrl:(NSString *)url andParams:(NSDictionary *)paramDic;

/**
 *  重写以完成样式自定义
 *
 */
- (void)createTableViewWithStyle:(UITableViewStyle)style;
- (void)createRefreshWithStyle:(RefreshStyle)style;

//请求刷新
- (void)requestForRefresh;

//请求下一页
- (void)requestForNextPage;

/**
 *  刷新当前页完成
 *  @param type 请求结果状态
 *  @param responseData 请求接口返回的数据
 */
- (void)requestForRefreshFinishStatu:(ResponseType)type response:(id)responseData;

/**
 *  请求下一页完成
 *
 *  @param responseData 请求下一页返回的数据
 */
- (void)reqeustForNextPageFinishStatu:(ResponseType)type response:(id)responseData;

@end
