//
//  global.h
//  unitoys
//
//  Created by sumars on 16/9/15.
//  Copyright © 2016年 sumars. All rights reserved.
//

/*
#ifndef global_h
#define global_h

#define defaultHost @"http://manage.ali168.com"

#define imageHost @"http://image4.ali168.com"

#define defaultPort @":8000"
*/



#define DEBUGMODE 1

#if DEBUGMODE

#define defaultHost @"http://apitest.unitoys.com/"

#else

#define defaultHost @"https://api.unitoys.com/"

#endif

#define isUseCallKit YES

//Color
#define RGB(r, g, b)    [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0] 
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define DefultColor [UIColor colorWithRed:(0 / 255.0) green:(160 / 255.0) blue:(233 / 255.0) alpha:1.0]
//背景
#define DefualtBackgroundColor [UIColor colorWithRed:(245 / 255.0) green:(245 / 255.0) blue:(245 / 255.0) alpha:1.0]
//分隔线
#define DefualtSeparatorColor [UIColor colorWithRed:(229 / 255.0) green:(229 / 255.0) blue:(229 / 255.0) alpha:1.0]


#define X(x) (x/375.0)*[UIScreen mainScreen].bounds.size.width;
#define Y(y) (y/667.0)*[UIScreen mainScreen].bounds.size.height;

//状态栏高度
#define STATUESVIEWHEIGHT 24
//状态栏中图片高度
#define STATUESVIEWIMAGEHEIGHT 20

#define apiAlipayNotify  defaultHost@"/api/AliPay/NotifyAsync";

#define kScreenWidthValue  [UIScreen mainScreen].bounds.size.width
#define kScreenHeightValue  [UIScreen mainScreen].bounds.size.height
#define kStatusBarHeight [UIApplication sharedApplication].statusBarFrame.size.height

#define kWeakSelf __weak typeof(self) weakSelf = self;

#define kSystemVersionValue [[UIDevice currentDevice].systemVersion floatValue]

#define INTERNATIONALSTRING(str) NSLocalizedString(str, nil)
//#define INTERNATIONALSTRING(str) (([[[NSLocale preferredLanguages] objectAtIndex:0] isEqual:@"zh-Hans"])?([[NSBundle mainBundle] localizedStringForKey:(str) value:@"" table:nil]):([[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"]] localizedStringForKey:str value:@"" table:nil]))

//如果不使用签名则按partner、expires、sign三个参数直接作为URL参数，其他则Post或是Get根据需要写入
//如果使用签名则按partner、expires、sign和TOKEN（登录后获得，12天失效）四个参数写进Header进行签名认证。其他则Post或是Get根据需要写入

//使用签名，获取软电话注册配置（打出，打入）
#define apiGetSecurityConfig defaultHost@"api/Config/GetSecurityConfig"

//使用签名，获取基本注册
#define apiGetBasicConfig defaultHost@"api/Config/GetBasicConfig"

//不用签名，APP升级
#define apiUpgrade defaultHost@"api/public/Upgrade"

//不用签名，获取首页banner图片
#define apiGetBannerList defaultHost@"api/config/getbannerlist"

//不用签名，获取首页产品列表
#define apiGetProductList defaultHost@"api/config/GetProductList"

//不用签名，发送短信验证码
#define apiSendSMS defaultHost@"api/Confirmation/SendSMS"

//不用签名，快速注册
#define apiRegisterUser defaultHost@"api/Register/Post"

//不用签名，忘记密码
#define apiForgetPassword defaultHost@"api/User/ForgotPassword"

//不用签名，用户登录
#define apiCheckLogin defaultHost@"api/Login/CheckLogin"

//判断token是否过期
#define apiGetLogin defaultHost@"api/Login/Get"

//使用签名，查询用户余额
#define apiGetUserAmount defaultHost@"api/User/GetUserAmount"

//使用签名，退出登录
#define apiLogout defaultHost@"api/Login/Logout"

//使用签名，获取运动总量
#define apiGetSportTotal defaultHost@"api/Sport/GetSportTotal"

//使用签名，查询所有国家，返回洲
#define apiCountryGet defaultHost@"api/Country/Get"

//使用签名，查询热门国家
#define apiCountryHot defaultHost@"api/Country/GetHot"

//使用签名，查询套餐列表
#define apiPackageGet defaultHost@"api/Package/Get"

//使用签名，查询国家套餐
#define apiPackageByCountry defaultHost@"api/Package/GetByCountry"

//使用签名，查询套餐详情
#define apiPackageByID defaultHost@"api/Package/GetByID"

//使用签名，查询轻松服务
#define apiPackageGetRelaxed defaultHost@"api/Package/GetRelaxed"

//使用签名，用户反馈
#define apiFeedback defaultHost@"api/Feedback/AddFeedback"

//使用签名，根据条件查询订单，分页
#define apiOrderList defaultHost@"api/Order/GetUserOrderList"

//使用签名，根据ID查询用户订单
#define apiOrderById defaultHost@"api/Order/GetByID"

//使用签名，订单套餐激活
#define apiOrderActivation defaultHost@"api/Order/Activation"
//使用签名， 本地激活完成
#define api defaultHost@"api/Order/ActivationLocalCompleted"

//使用签名，查询订单卡数据
#define apiQueryOrderData defaultHost@"api/Order/QueryOrderData"

//使用签名，订单套餐激活本地完成
#define apiActivationLocalCompleted defaultHost@"api/Order/ActivationLocalCompleted"

//使用签名，创建订单，提交订单
#define apiOrderAdd defaultHost@"api/Order/Add"

//使用签名，取消订单
#define apiOrderCancel defaultHost@"api/Order/Cancel"

//使用签名，充值，充值，给账户充值
#define apiRecharge defaultHost@"api/Payment/Add"

//使用签名，通过用户余额支付套餐订单
#define apiPayOrderByUserAmount defaultHost@"api/Order/PayOrderByUserAmount"

//使用签名，查询用户订单使用余量
#define apiGetUserOrderUsageRemaining defaultHost@"api/Order/GetUserOrderUsageRemaining"

//使用签名，获取用户消费记录
#define apiGetUserBill defaultHost@"api/User/GetUserBill"

//使用签名，获取软电话注册配置（打出，打入）
#define apiGetSecrityConfig defaultHost@"api/config/GetSecurityConfig"

//使用签名，查询通话记录
#define apiGetSpeakRecord defaultHost@"api/SpeakRecord/Get"

//使用签名，添加通话记录并且扣除用户通话费用
#define apiAddSpeakRecord defaultHost@"api/SpeakRecord/Add"

//使用签名，获取本次可以通话的最长秒数
#define apiGetMaxmimumPhoneCallTime defaultHost@"api/User/GetMaximumPhoneCallTime"

//使用签名，app调用支付成功返回的接口，OrderNum,PayDate,Amount,Key
#define apiPayNotifyAnsync defaultHost@"api/Order/PayNotifyAsync"

//使用签名，生成预支付ID，微信
#define apiGetPrepayID defaultHost@"api/WxPay/GetPayId"

//使用签名，进行短信发送
#define apiSMSSend defaultHost@"api/SMS/Send"

//使用签名，获取最后一条短信列表（短信一级界面展示）
#define apiSMSLast  defaultHost@"api/SMS/GetUserContactTelLastSMS"

//使用签名，获取联系人短信
#define apiSMSByTel  defaultHost@"api/SMS/GetByTel"

//使用签名，更新用户头像
#define apiModifyUserHead defaultHost@"api/User/ModifyUserHead"

//使用签名，更新用户基本资料和体形
#define apiUpdateUserInfo defaultHost@"api/User/UpdateUserInfoAndUserShape"

//使用签名，上传历史步数
#define apiAddHistorys defaultHost@"api/Sport/AddHistorys"

//使用签名，获取某天的运动时间段记录
#define apiGetTimePeriodByDate defaultHost@"api/Sport/GetTimePeriodByDate"

//使用签名，获取记录的运动日期
#define apiGetRecordDate defaultHost@"api/Sport/GetRecordDate"

//使用签名，绑定手环
#define apiBind defaultHost@"api/DeviceBracelet/Bind"

//使用签名，解除绑定
#define apiUnBind defaultHost@"api/DeviceBracelet/UnBind"

//使用签名，充值卡充值余额
#define apiRechargeCard defaultHost@"api/PaymentCard/Recharge"

//使用签名，绑定礼包卡
#define apiGiftCardBind defaultHost@"api/GiftCard/Bind"

//使用签名，激活大王卡
#define apiActivationKindCard defaultHost@"api/Order/ActivationKindCard"

//使用签名，判断用户是否存在制定套餐
#define apiCheckUsedExistByPageCategory defaultHost@"api/Order/CheckUsedExistByPageCategory"

//使用签名，手环设备查询
#define apiDeviceBracelet defaultHost@"api/DeviceBracelet/Get"

//使用签名，查询手环设备是否被其他用户绑定
#define apiIsBind defaultHost@"api/DeviceBracelet/IsBind"

//使用签名，更新手环设备连接信息
#define apiUpdateConnectInfo defaultHost@"api/DeviceBracelet/UpdateConnectInfo"

//使用签名，空中升级
#define apiDeviceBraceletOTA defaultHost@"api/DeviceBracelet/OTA"

//使用签名，获取手环设备注册状态
#define apiGetRegStatus defaultHost@"api/DeviceBracelet/GetRegStatus"

//删除单个联系人短信
#define apiDeletesByTel  defaultHost@"api/SMS/DeletesByTel"

//删除多个联系人短信
#define apiDeletesByTels  defaultHost@"api/SMS/DeletesByTels"

//删除多条短信内容
#define apiDeletes  defaultHost@"api/SMS/Deletes"

//短信发送错误-重试
#define apiSendRetryForError  defaultHost@"api/SMS/SendRetryForError"

//使用签名，获取用户配置
#define apiCheckUserConfig defaultHost@"api/UsersConfig/Get"

//使用签名，上传用户设置
#define apiUploadConfig defaultHost@"api/UsersConfig/UploadConfig"

//添加黑名单
#define apiBlackListAdd defaultHost@"api/BlackList/Add"

//删除黑名单
#define apiBlackListDelete defaultHost@"api/BlackList/Delete"

//查询黑名单列表
#define apiBlackListGet defaultHost@"api/BlackList/Get"

//查询省心服务推送消息
#define apiPushContentGet defaultHost@"api/PushContent/Get"

//环形进度条密集度系数
#define AnnularProgressBar @"60"

//客服邮箱
#define EMAIL @"service@unitoys.com"
//#define EMAIL @"630893613@qq.com"

//客服电话
#define TELEPHONE @"075532979727"

//端口
#define PORT 4567
//#define TCPPORT 20016

//本地服务器
#define webPath [[NSBundle mainBundle] pathForResource:@"CertificateFiles" ofType:nil]

//IP地址
#define SERVERIP @"127.0.0.1"
//#define SERVER "192.168.1.145"
//#define TCPIP @"120.25.91.50:22"
//#define TCPIP @"120.25.161.113"

#define TCPFIRSTSUBNOT @"108a0400"//第一个头
#define TCPCOMMUNICATEID @"00000000"//会话id
#define TCPGOIP @"010101"//请求goip模块
#define TCPLIFETIME @"6501b4"//连接存活时间
#define TCPCHECKPREREAD @"6b0101"//请求预读数据
#define TCPCONNECT @"790101"//数据连接协议
#define TCPUUWIFI @"9606757573696d00"//uuwifi设备编号
#define TCPSLOT @"a009757573696d2e303100"//模块位置描述
#define TCPIMEI @"aa0100"//模块IMEI
#define TCPMODTYPE @"ab0100"//模块类型
#define TCPMODVER @"ac0100"//模块版本
#define TCPSIMLOCAL @"b40100"//sim卡位置描述
#define TCPSIMNUMBER @"c00100"//sim卡卡号
#define TCPSIMBALANCE @"c10100"//sim卡余额
#define TCPVERSIONTYPE @"c90101"//设备类型(区分安卓)

#pragma mark TCP断开状态
#define SocketCloseByUser @"SocketCloseByUser"
#define SocketCloseByNet @"SocketCloseByNet"
#define SocketCloseByServer @"SocketCloseByServer"


#pragma mark 顶端状态
//蓝牙未开
#define HOMESTATUETITLE_BLNOTOPEN @"蓝牙未开"
#define HOMESTATUE_BLNOTOPEN @"homeStatue_noBlToConnect"
//未绑定
#define HOMESTATUETITLE_NOTBOUND @"未绑定"
#define HOMESTATUE_NOTBOUND @"homeStatue_nobound"
//未插卡
#define HOMESTATUETITLE_NOTINSERTCARD @"未插卡"
#define HOMESTATUE_NOTINSERTCARD @"homeStatue_noInsert"
//未连接
#define HOMESTATUETITLE_NOTCONNECTED @"未连接"
#define HOMESTATUE_NOTCONNECTED @"homeStatue_noConnect"
//连接中
#define HOMESTATUETITLE_CONNECTING @"连接中"
#define HOMESTATUE_CONNECTING @"homeStatue_isConnecting"
//正在注册
#define HOMESTATUETITLE_REGISTING @"注册中"
#define HOMESTATUE_REGISTING @"homeStatue_isConnecting"
//无套餐
#define HOMESTATUETITLE_NOPACKAGE @"无套餐"
#define HOMESTATUE_NOPACKAGE @"homeStatue_noPackge"
//注册失败
#define HOMESTATUETITLE_NOSIGNAL @"注册失败"
#define HOMESTATUE_NOSIGNAL @"homeStatue_noSignal"
//信号强
#define HOMESTATUETITLE_SIGNALSTRONG @"信号强"
#define HOMESTATUE_SIGNALSTRONG @"homeStatue_signalStrong"
//爱小器卡
#define HOMESTATUETITLE_AIXIAOQICARD @"爱小器卡"
#define HOMESTATUE_AIXIAOQICARD @"homeStatue_noSignal"
//服务未开启
#define HOMESTATUETITLE_NOTSERVICE @"服务未开启"
//当前网络不可用
#define HOMESTATUETITLE_NETWORKCANNOTUSE @"当前网络不可用"
//读卡失败
#define HOMESTATUETITLE_READCARDFAIL @"读取卡失败"


#pragma mark 运营商类型
//电信
#define TELECOM @[@"133", @"149", @"153", @"173", @"177", @"180", @"181", @"189"]
//联通
#define UNICOM @[@"130", @"131", @"132", @"145", @"155", @"156", @"171", @"175", @"176", @"185", @"186"]
//移动
#define CMCC @[@"134", @"135", @"136", @"137", @"138", @"139", @"147", @"150", @"151", @"152", @"157", @"158", @"159", @"178", @"182", @"183", @"184", @"187", @"188"]


#pragma 蓝牙相关
//蓝牙的设备名称
#define MYDEVICENAME @"unitoys unibox"
#define MYDEVICENAMEUNITOYS @"unitoys"
#define MYDEVICENAMEUNIBOX @"unibox"

//服务1的UUID
#define UUIDFORSERVICE1SERVICE @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
//服务1里面写属性特征
#define UUIDFORSERVICE1CHARACTERISTICTOWRITE @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
//服务1里面通知属性特征1
#define UUIDFORSERVICE1CHARACTERISTICTONOTIF @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
//服务1里面通知属性特征2
#define UUIDFORSERVICE1CHARACTERISTICTONOTIF2 @"6E400004-B5A3-F393-E0A9-E50E24DCCA9F"
//服务1里面通知属性特征3
#define UUIDFORSERVICE1CHARACTERISTICTONOTIF3 @"6E400005-B5A3-F393-E0A9-E50E24DCCA9F"
//蓝牙扫描时间
#define BLESCANTIME 20


#define LBEUUID @"F9D77679-66D1-15A7-1052-EAD426D72C61"

//#ifndef __OPTIMIZE__
//
//#define NSLog(...) NSLog(__VA_ARGS__)
//
//#else
//
//#define NSLog(...) {}
//
//#endif

/*
#endif */
