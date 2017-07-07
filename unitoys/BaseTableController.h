//
//  BaseTableController.h
//  CloudEgg
//
//  Created by ququ-iOS on 15/12/26.
//  Copyright © 2015年 ququ-iOS. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "global.h"

#import "SSNetworkRequest.h"
#import "MBProgressHUD.h"
#import "UIImageView+WebCache.h"

/**
 *  HUD自动隐藏
 *
 */
#define HUDNormal(msg) {MBProgressHUD *hud=[MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication].delegate window] animated:NO];\
hud.mode = MBProgressHUDModeText;\
hud.minShowTime=1;\
hud.detailsLabel.text= msg;\
hud.detailsLabel.font = [UIFont systemFontOfSize:17];\
[hud hideAnimated:YES afterDelay:1];\
}

/**
 *  HUD顶部自动隐藏
 *
 */
#define HUDNormalTop(msg) {MBProgressHUD *hud=[MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication].delegate window] animated:NO];\
hud.mode = MBProgressHUDModeText;\
hud.minShowTime=1;\
hud.detailsLabel.text= msg;\
hud.detailsLabel.font = [UIFont systemFontOfSize:17];\
hud.yOffset =  -70;\
[hud hideAnimated:YES afterDelay:1];\
}


/**
 *  HUD不自动隐藏最小时间为0
 *
 */
#define HUDNoStop1(msg)    {MBProgressHUD *hud=[MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication].delegate window] animated:NO];\
hud.detailsLabelText = msg;\
hud.detailsLabelFont = [UIFont systemFontOfSize:17];\
hud.mode = MBProgressHUDModeIndeterminate;}


/**
 *  HUD隐藏
 *
 */
#define HUDStop [MBProgressHUD hideAllHUDsForView:[[UIApplication sharedApplication].delegate window] animated:NO];

//加载图片
#define setImage(ImageView,urlstr)   [ImageView sd_setImageWithURL:[NSURL URLWithString:urlstr] placeholderImage:nil];

@interface BaseTableController : UITableViewController

@property (strong,nonatomic) NSMutableDictionary *params;

@property (strong,nonatomic) NSMutableDictionary *headers;

@property (readwrite) BOOL checkToken;

- (NSString *)md5:(NSString *)str;

- (void)getBasicParam;

- (void)getBasicHeader;

- (NSString *)getParamStr;

-(void)setExtraCellLineHidden: (UITableView *)tableView;

- (NSString *)compareCurrentTimeString:(NSString *)compareDateString;

-(NSString *) compareCurrentTime:(NSDate*) compareDate;

-(NSString *) formatTime:(NSDate*) formatDate;

- (NSDate*)convertDate :(NSString *)timestamp;

-(NSString*)convertNull:(id)object;

- (void)showAlertWithMessage:(NSString *)message;//显示警告框

- (void)leftButtonAction;

-(void)setLeftButton:(id)LeftButton;

-(void)leftButtonClick;

- (BOOL)isShowLeftButton;

-(void)setRightButton:(id)rightButton;
-(void)rightButtonClick;

- (void)dj_alertAction:(UIViewController *)controller alertTitle:(NSString *)alertTitle actionTitle:(NSString *)actionTitle message:(NSString *)message alertAction:(void (^)())alertAction;

- (void)dj_alertAction:(UIViewController *)controller alertTitle:(NSString *)alertTitle leftActionTitle:(NSString *)leftActionTitle rightActionTitle:(NSString *)rightActionTitle message:(NSString *)message leftAlertAction:(void (^)())leftAlertAction rightAlertAction:(void (^)())rightAlertAction;

- (BOOL)isBlankString:(NSString *)string;

- (NSString *)checkLinkNameWithPhoneStr:(NSString *)phoneStr;

//短信不显示组名
- (NSString *)checkLinkNameWithPhoneStrNoGroupName:(NSString *)phoneStr;
//短信去除重复组名
- (NSString *)checkLinkNameWithPhoneStrMergeGroupName:(NSString *)phoneStr;

- (BOOL)isWXAppInstalled;//判断是否安装指定版本的微信
- (void)setRedLabel:(UILabel *)label;
- (void)setStatuesLabelTextWithLabel:(UILabel *)label String:(NSString *)string;


/**
 是否显示状态栏
 */
- (BOOL)isNeedToShowBLEStatue;

/**
 拨打电话的时候显示提示
 */
- (BOOL)checkBLEStatueAndAlert;
@end
