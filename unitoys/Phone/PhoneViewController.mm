//
//  PhoneViewController.mm
//  unitoys
//
//  Created by sumars on 16/10/25.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "PhoneViewController.h"
//#import "WriteMessageViewController.h"

#import "NewMessageViewController.h"
#import "PhoneRecordCell.h"
#import "MessageRecordCell.h"

#import "CallingViewController.h"

#import "MJViewController.h"

#import "SipEngineManager.h"

#import "MJRefresh.h"
#import "FMDatabase.h"
#import "AddressBookManager.h"
#import "ContactModel.h"
#import "CallComingInViewController.h"
#import "VSWManager.h"
#import "BlueToothDataManager.h"
#import "SearchContactsCell.h"

#import "UNCallKitCenter.h"
#import <SSZipArchive/SSZipArchive.h>

//#import "JSONModel.h"
#import <MJExtension/MJExtension.h>
#import <Reachability/Reachability.h>

@interface PhoneViewController ()
{
    UNCallKitCenter *callCenter;
}


@property (nonatomic, strong)NSDictionary *userInfo;
@property (nonatomic, strong)CallComingInViewController *callCominginVC;

//当前是否为搜索状态
@property (nonatomic, assign) BOOL isSearchStatu;

//处理过的拨打记录列表
@property (nonatomic, copy) NSArray *searchPhoneRecords;
//联系人列表
@property (nonatomic, copy) NSArray *contactsLists;
//搜索列表
@property (nonatomic, strong) NSMutableArray *searchLists;

@end


static NSString *searchContactsCellID = @"SearchContactsCell";
@implementation PhoneViewController

- (NSMutableArray *)searchLists
{
    if (!_searchLists) {
        _searchLists = [NSMutableArray array];
    }
    return _searchLists;
}

- (NSArray *)contactsLists
{
    if (!_contactsLists) {
        //获取联系人信息
        _contactsLists = [[AddressBookManager shareManager].dataArr copy];
    }
    return _contactsLists;
}

- (NSArray *)searchPhoneRecords
{
    if (!_searchPhoneRecords) {
        //去除记录重复
        NSMutableArray *tempArray = [NSMutableArray array];
        [_arrPhoneRecord enumerateObjectsUsingBlock:^(NSArray *objArray, NSUInteger idx, BOOL * _Nonnull stop) {
//            BOOL isRepeat = NO;
//            for (NSDictionary *tempDict in tempArray) {
//                if (([[obj objectForKey:@"destnumber"] isEqualToString:[tempDict objectForKey:@"destnumber"]] && [[obj objectForKey:@"hostnumber"] isEqualToString:[tempDict objectForKey:@"hostnumber"]])) {
//                    isRepeat = YES;
//                    break;
//                }
//            }
//            if (!isRepeat) {
//                [tempArray addObject:obj];
//            }
            if (objArray.count) {
                [tempArray addObject:objArray[0]];
            }
        }];
        
        _searchPhoneRecords = [tempArray copy];
        
//        _searchPhoneRecords = [_arrPhoneRecord copy];
    }
    return _searchPhoneRecords;
}

//收到重新登入通知后，注销Sip账号
- (void)unregister {
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    
    if (theSipEngine->AccountIsRegstered()) {
        theSipEngine->DeRegisterSipAccount();
    }
}

- (BOOL)initEngine {
    [[SipEngineManager instance] Init];
    [[SipEngineManager instance] LoadConfig];
    
    [[SipEngineManager instance] setCallDelegate:self];
    
    [[SipEngineManager instance] setRegistrationDelegate:self];
    
    [self doRegister];
    
    [self getMaxPhoneCall];
    
    //读取本地缓存的账号信息
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    self.userInfo = [[NSDictionary alloc] initWithDictionary:userdata];
    
    //添加通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAddressBook) name:@"addressBookChanged" object:@"addressBook"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callingAction:) name:@"CallingAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeCallAction:) name:@"MakeCallAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeUnitysCallAction:) name:@"MakeUnitysCallAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessage) name:@"sendMessageSuccess" object:@"sendMessageSuccess"];
    
    return YES;
}



- (void)refreshAddressBook {
    if (_arrPhoneRecord) {
        [self.arrPhoneRecord removeAllObjects];
        [self loadPhoneRecord];
    }
    if (_arrMessageRecord) {
        self.arrMessageRecord = nil;
        [self loadMessage];
    }
}


- (BOOL) isZeroStarted :(NSString *)number {
    if (number && number.length) {
        if ([[number substringToIndex:1] isEqualToString:@"0"]) {
            return YES;
        }else{
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)unZipNumberPhoneDB
{
    // 取得沙盒目录
    NSString *localPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // 要检查的文件目录
    NSString *dbPath = [localPath  stringByAppendingPathComponent:@"number_location.db"];
    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"number_location" ofType:@"zip"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断是否有数据库文件
    if (![fileManager fileExistsAtPath:dbPath]) {
        NSLog(@"数据库文件不存在");
        //判断是否有解压文件
        if ([fileManager fileExistsAtPath:zipPath]) {
            NSLog(@"解压文件存在");
            //解压文件
            if ([SSZipArchive unzipFileAtPath:zipPath toDestination:localPath overwrite:YES password:nil error:nil]) {
//                NSError *error = nil;
//                BOOL isDelete = [fileManager removeItemAtPath:zipPath error:&error];
//                if (isDelete) {
//                    NSLog(@"删除成功");
//                }else{
//                    NSLog(@"删除失败");
//                }
            }else{
                NSLog(@"解压失败");
            }
        }
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //解压联系人数据库
    [self unZipNumberPhoneDB];
    
    self.navigationItem.leftBarButtonItem = nil;
    self.btnWriteMessage.hidden = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [UIView new];
    
    
    NSString *strPhoneRecordCell = @"PhoneRecordCell";
    NSString *strMessageRecordCell = @"MessageRecordCell";
    
    UINib * phoneRecordNib = [UINib nibWithNibName:strPhoneRecordCell bundle:nil];
    UINib * messageRecordNib = [UINib nibWithNibName:strMessageRecordCell bundle:nil];
    
    [self.tableView registerNib:phoneRecordNib forCellReuseIdentifier:strPhoneRecordCell];
    [self.tableView registerNib:messageRecordNib forCellReuseIdentifier:strMessageRecordCell];
    [self.tableView registerNib:[UINib nibWithNibName:searchContactsCellID bundle:nil] forCellReuseIdentifier:searchContactsCellID];
    
    if (!_arrPhoneRecord) {
        [self loadPhoneRecord];
    }
    
    self.page = 1;
    
    if (!_arrMessageRecord) {
        [self loadMessage];
    }
    // Do any additional setup after loading the view.
    
    
    __typeof(self) weakSelf = self;
    
    self.phonePadView.completeBlock = ^(NSString *btnText,NSInteger btnTag){
        //点击了删除按钮
        /*
         if (btnTag == 9) {
         [weakSelf clickDeleteBtn];
         }else if (btnTag == 11){
         //点击了完成按钮
         [weakSelf.NumKeyBoard dismiss];
         }else{
         //点击了数字按钮
         [weakSelf.textField changetext:btnText];
         }*/
        
        if (weakSelf.phonePadView.inputedPhoneNumber.length>0) {
            //当前为搜索状态
            weakSelf.isSearchStatu = YES;
            [weakSelf.segmentType setHidden:YES];
            if (weakSelf.lblPhoneNumber) {
                [weakSelf.lblPhoneNumber setHidden:NO];
                weakSelf.lblPhoneNumber.text = weakSelf.phonePadView.inputedPhoneNumber;
            } else {
                UILabel *lblPhoneNumber = [[UILabel alloc] initWithFrame:weakSelf.navigationController.navigationBar.bounds];
                weakSelf.lblPhoneNumber = lblPhoneNumber;
                [weakSelf.lblPhoneNumber setTextAlignment:NSTextAlignmentCenter];
                [weakSelf.lblPhoneNumber setTextColor:[UIColor whiteColor]];
                [weakSelf.lblPhoneNumber setBackgroundColor:[UIColor clearColor]];
                weakSelf.lblPhoneNumber.text = weakSelf.phonePadView.inputedPhoneNumber;
                [weakSelf.navigationController.navigationBar addSubview:weakSelf.lblPhoneNumber];
            }
            
            //self.title = self.phonePadView.inputedPhoneNumber;
            
            [weakSelf showOperation];
            
            //搜索电话并展示
            [weakSelf searchInfoWithString:weakSelf.lblPhoneNumber.text];
            [weakSelf.tableView reloadData];
            
        }else{
            
            //当前不为搜索状态
            weakSelf.isSearchStatu = NO;
            [weakSelf.segmentType setHidden:NO];
            if (weakSelf.lblPhoneNumber) {
                [weakSelf.lblPhoneNumber setHidden:YES];
            }
            
            if (weakSelf.callView.hidden==NO) {
                weakSelf.callView.hidden = YES;
            }
        }
        
    };
    

    /*
    [[SipEngineManager instance] Init];
    [[SipEngineManager instance] LoadConfig];
    
    [[SipEngineManager instance] setCallDelegate:self];
    
    [[SipEngineManager instance] setRegistrationDelegate:self];
    
    [self doRegister];
    
    [self getMaxPhoneCall];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callingAction:) name:@"CallingAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeCallAction:) name:@"MakeCallAction" object:nil];*/
}

//- (void)viewWillAppear:(BOOL)animated {
//    self.segmentType.selectedSegmentIndex = 0;
//    self.btnWriteMessage.hidden = YES;
//    [self.phonePadView setHidden:NO];
//    [self.tableView setNeedsUpdateConstraints];
//    [self.tableView updateConstraints];
//}


//谓词搜索
- (void)searchInfoWithString:(NSString *)searchText
{
    NSString *searchString = [NSString stringWithUTF8String:searchText.UTF8String];
    //    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", searchString];
    NSPredicate *contactsPredicate = [NSPredicate predicateWithFormat:@"phoneNumber CONTAINS[c] %@ || allPinyinNumber CONTAINS[c] %@ || headerPinyinNumber CONTAINS[c] %@", searchString, searchString, searchString];
    NSPredicate *recordsPredicate = [NSPredicate predicateWithFormat:@"hostnumber CONTAINS[c] %@ || destnumber CONTAINS[c] %@", searchString, searchString];
    //用predicateWithFormat创建一个谓词，name作为键路径
    if (_searchLists!= nil) {
        [_searchLists removeAllObjects];
    }
    
    NSArray *filter = [self filterNumerWithSearchList:[self.searchPhoneRecords filteredArrayUsingPredicate:recordsPredicate] SearchText:searchText];
    [self.searchLists addObjectsFromArray:filter];
    [self.searchLists addObjectsFromArray:[self.contactsLists filteredArrayUsingPredicate:contactsPredicate]];
    [self.tableView reloadData];
}

- (NSArray *)filterNumerWithSearchList:(NSArray *)searchLists SearchText:(NSString *)searchText
{
    NSMutableArray *tempArray = [NSMutableArray array];
    for (NSDictionary *recordDict in searchLists) {
        if ([[recordDict objectForKey:@"calltype"] isEqualToString:@"来电"]) {
            if ([(NSString *)[recordDict objectForKey:@"hostnumber"] containsString:searchText]) {
                [tempArray addObject:recordDict];
            }
        }else{
            if ([(NSString *)[recordDict objectForKey:@"destnumber"] containsString:searchText]) {
                [tempArray addObject:recordDict];
            }
        }
    }
    return tempArray;
}

- (void)loadMessage {
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@"1",@"pageNumber", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest getRequest:apiSMSLast params:params success:^(id responseObj) {
        //
        //KV来存放数组，所以要用枚举器来处理
        /*
         NSEnumerator *enumerator = [[responseObj objectForKey:@"data"] keyEnumerator];
         id key;
         while ((key = [enumerator nextObject])) {
         [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
         }*/
        NSLog(@"查询到的用户数据：%@",responseObj);
        [self.tableView.mj_header endRefreshing];
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            _arrMessageRecord = [responseObj objectForKey:@"data"];
            if (self.phoneOperation==1) {
                if (_arrMessageRecord.count>=20) {
                    self.tableView.mj_footer.hidden = NO;
                }else{
                    self.tableView.mj_footer.hidden = YES;
                }
            }
            
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"请求短信数据失败");
        }
        
    } failure:^(id dataObj, NSError *error) {
        [self.tableView.mj_header endRefreshing];
    } headers:self.headers];
}

//短信加载更多数据
- (void)loadMoreMessage {
    
    if (self.tableView.mj_header.isRefreshing) {
        [self.tableView.mj_footer endRefreshing];
        return;
    }
    
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"pageSize",@(self.page+1),@"pageNumber", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);

    [SSNetworkRequest getRequest:apiSMSLast params:params success:^(id responseObj) {
        //
        //KV来存放数组，所以要用枚举器来处理
        /*
         NSEnumerator *enumerator = [[responseObj objectForKey:@"data"] keyEnumerator];
         id key;
         while ((key = [enumerator nextObject])) {
         [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
         }*/
        NSLog(@"查询到的用户数据：%@",responseObj);
//        [self.tableView.mj_footer endRefreshing];
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            NSArray *arrNewMessages = [responseObj objectForKey:@"data"];
            
            if (arrNewMessages.count>0) {
                self.page = self.page + 1;
                _arrMessageRecord = [_arrMessageRecord arrayByAddingObjectsFromArray:arrNewMessages];
                [self.tableView.mj_footer endRefreshing];
            }else{
//                [self.tableView.mj_header endRefreshing];
//                self.tableView.mj_footer.hidden = NO;
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
            
            [self.tableView reloadData];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            HUDNormal(INTERNATIONALSTRING(@"请求失败"))
            [self.tableView.mj_footer endRefreshing];
        }
        
    } failure:^(id dataObj, NSError *error) {
//        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
    } headers:self.headers];
}


//- (void)loadPhoneRecord {
//    self.checkToken = YES;
//    
//    [self getBasicHeader];
//    
//    _arrPhoneRecord = [[NSMutableArray alloc] init];
//    
//    
//    //Home目录
//    //NSString *homeDirectory = NSHomeDirectory();
//    
//    //Document目录
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *path = [paths objectAtIndex:0];
//    
//    path = [path stringByAppendingPathComponent:@"callrecord.db"];
//    
//    FMDatabase *db = [FMDatabase databaseWithPath:path];
//    
//    if (![db open]) {
//        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"创建通话记录失败" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
//        return;
//        
//    }else{
//        //监测数据库中我要需要的表是否已经存在
//        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord" ];
//        FMResultSet *rs = [db executeQuery:existsSql];
//        
//        if ([rs next]) {
//            NSInteger count = [rs intForColumn:@"countNum"];
//            NSLog(@"The table count: %li", count);
//            if (count == 1) {
//                NSLog(@"log_keepers table is existed.");
//                NSString *dataSql = @"select * from CallRecord";
//                FMResultSet *rs = [db executeQuery:dataSql];
//                
//                if ([rs columnCount]==5) { //缺少status字段
//                    NSLog(@"添加数据库字段");
//                    [db executeUpdate:@"ALTER TABLE CallRecord ADD COLUMN status Integer"];
//                    NSString *dataSql = @"select * from CallRecord";
//                    rs = [db executeQuery:dataSql];
//                }
//                
//                while ([rs next]) {
//                    //添加数据到arrPhoneCallRecord
//                    NSDictionary *dicCallRecord = [[NSDictionary alloc] initWithObjectsAndKeys:[rs stringForColumn:@"hostnumber"],@"hostnumber",[rs stringForColumn:@"destnumber"],@"destnumber",[self convertDate:[rs stringForColumn:@"calltime"]],@"calltime",[rs stringForColumn:@"calltype"],@"calltype",[rs stringForColumn:@"location"],@"location",[rs stringForColumn:@"status"],@"status",nil];
//                    
//                    [self.arrPhoneRecord insertObject:dicCallRecord atIndex:0];
//                }
//                return;
//            }
//            
//            NSLog(@"log_keepers is not existed.");
//            //创建表
//            //[membersDB executeUpdate:@"CREATE TABLE PersonList (Name text, Age integer, Sex integer,Phone text, Address text, Photo blob)"];
//            [db executeUpdate:@"CREATE TABLE CallRecord (hostnumber Text, destnumber Text, calltime TimeStamp, calltype Text, location Text, status Integer)"];
//        }else{
//            //加载数据到列表
//            
//            NSString *dataSql = @"select * from CallRecord";
//            FMResultSet *rs = [db executeQuery:dataSql];
//            
//            while ([rs next]) {
//                //添加数据到arrPhoneCallRecord
//                NSDictionary *dicCallRecord = [[NSDictionary alloc] initWithObjectsAndKeys:[rs stringForColumn:@"hostnumber"],@"hostnumber",[rs stringForColumn:@"destnumber"],@"destnumber",[self convertDate:[rs stringForColumn:@"calltime"]],@"calltime",[rs stringForColumn:@"calltype"],@"calltype",[rs stringForColumn:@"location"],@"location",[rs stringForColumn:@"status"],@"status",nil];
//                
//                [self.arrPhoneRecord insertObject:dicCallRecord atIndex:0];
//            }
//        }
//        [rs close];
//    }
//
//    [self.tableView reloadData];
//}


- (void)loadPhoneRecord {
    self.checkToken = YES;
    
    [self getBasicHeader];
    
    _arrPhoneRecord = [[NSMutableArray alloc] init];
    //Home目录
    //NSString *homeDirectory = NSHomeDirectory();
    
    //Document目录
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
//    path = [path stringByAppendingPathComponent:@"callrecord.db"];
    path = [path stringByAppendingPathComponent:@"callrecord2.db"];
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    if (![db open]) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"创建通话记录失败") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil] show];
        return;
    }else{
        //监测数据库中我要需要的表是否已经存在
        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord" ];
        FMResultSet *rs = [db executeQuery:existsSql];
        
        if ([rs next]) {
            NSInteger count = [rs intForColumn:@"countNum"];
            NSLog(@"The table count: %li", count);
            if (count == 1) {
                NSLog(@"log_keepers table is existed.");
                //升序,将数据插入到最前面,因此最先插入的显示在最后
                NSString *dataSql = @"select * from CallRecord order by calltime asc";
                FMResultSet *rs = [db executeQuery:dataSql];
                
//                if ([rs columnCount]==5) { //缺少status字段
//                    NSLog(@"添加数据库字段");
//                    [db executeUpdate:@"ALTER TABLE CallRecord ADD COLUMN status Integer"];
//                    NSString *dataSql = @"select * from CallRecord";
//                    rs = [db executeQuery:dataSql];
//                }
                
                while ([rs next]) {
                    //添加数据到arrPhoneCallRecord
//                    (datas, calltime, dataid)
                    NSString *jsonStr1 = [rs stringForColumn:@"datas"];
                    NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
                    NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
//                    NSDictionary *dicCallRecord = [[NSDictionary alloc] initWithObjectsAndKeys:[rs stringForColumn:@"hostnumber"],@"hostnumber",[rs stringForColumn:@"destnumber"],@"destnumber",[self convertDate:[rs stringForColumn:@"calltime"]],@"calltime",[rs stringForColumn:@"calltype"],@"calltype",[rs stringForColumn:@"location"],@"location",[rs stringForColumn:@"status"],@"status",nil];
                    [self.arrPhoneRecord insertObject:dataArray atIndex:0];
                }
//                return;
            }
            
            NSLog(@"log_keepers is not existed.");
            //创建表
            //[membersDB executeUpdate:@"CREATE TABLE PersonList (Name text, Age integer, Sex integer,Phone text, Address text, Photo blob)"];
//            [db executeUpdate:@"CREATE TABLE CallRecord (hostnumber Text, destnumber Text, calltime TimeStamp, calltype Text, location Text, status Integer)"];
            
//            [db executeUpdate:@"CREATE TABLE CallRecord (datas Text, calltime TimeStamp, dataid text)"];
        }else{
            //加载数据到列表
            //升序,将数据插入到最前面,因此最先插入的显示在最后
            NSString *dataSql = @"select * from CallRecord order by calltime asc";
            FMResultSet *rs = [db executeQuery:dataSql];
            
            while ([rs next]) {
                //添加数据到arrPhoneCallRecord
//                NSDictionary *dicCallRecord = [[NSDictionary alloc] initWithObjectsAndKeys:[rs stringForColumn:@"hostnumber"],@"hostnumber",[rs stringForColumn:@"destnumber"],@"destnumber",[self convertDate:[rs stringForColumn:@"calltime"]],@"calltime",[rs stringForColumn:@"calltype"],@"calltype",[rs stringForColumn:@"location"],@"location",[rs stringForColumn:@"status"],@"status",nil];
//                
//                [self.arrPhoneRecord insertObject:dicCallRecord atIndex:0];
                
                NSString *jsonStr1 = [rs stringForColumn:@"datas"];
                NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
                NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
                //                    NSDictionary *dicCallRecord = [[NSDictionary alloc] initWithObjectsAndKeys:[rs stringForColumn:@"hostnumber"],@"hostnumber",[rs stringForColumn:@"destnumber"],@"destnumber",[self convertDate:[rs stringForColumn:@"calltime"]],@"calltime",[rs stringForColumn:@"calltype"],@"calltype",[rs stringForColumn:@"location"],@"location",[rs stringForColumn:@"status"],@"status",nil];
                [self.arrPhoneRecord insertObject:dataArray atIndex:0];
            }
        }
        [rs close];
        [db close];
    }
    
    [self.tableView reloadData];
}


- (NSString *)numberFromCid :(NSString *)cid {
    //原本考虑正则，但规则比较简单
    if (([[cid substringToIndex:3] isEqualToString:@"981"])&&[cid rangeOfString:@"#"].length) {
        return [cid substringWithRange:NSMakeRange(3, [cid rangeOfString:@"#"].location-3)];
    } else if ([[cid substringToIndex:3] isEqualToString:@"986"]) {
        return [cid substringFromIndex:8];
    } else {
        return cid;
    }
}



- (BOOL)addPhoneRecordWithHostcid:(NSString *)hostcid Destcid:(NSString *)destcid Calltime:(NSDate *)calltime Calltype:(NSString *)calltype {
    //status,来电是否接听
    NSTimeInterval a = [calltime timeIntervalSince1970];
    NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
//    NSTimeInterval callTimeNumber = [calltime timeIntervalSince1970];
    
    NSMutableDictionary *dicPhoneRecord = [[NSMutableDictionary alloc] initWithObjectsAndKeys:timestemp,@"calltime",calltype,@"calltype",[self numberFromCid:hostcid],@"hostnumber",[self numberFromCid:destcid],@"destnumber",@0,@"status", nil];  //时间写入记录时不需要转成字符
    [dicPhoneRecord setObject:@"未知" forKey:@"location"];
    
    NSString *localPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // 要检查的文件目录
    NSString *path = [localPath  stringByAppendingPathComponent:@"number_location.db"];
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    if (![db open]) {
        NSLog(@"数据库打开失败！");
    }else{
        NSString *number;
        if ([calltype isEqualToString:@"去电"]) {
            number = [dicPhoneRecord objectForKey:@"destnumber"];
        } else {
            number = [dicPhoneRecord objectForKey:@"hostnumber"];
        }

        if ([self isZeroStarted:number]) {
            NSString *prefix;
            if (number.length >= 3) {
                if ([[number substringToIndex:2] isEqualToString:@"01"]) {
                    prefix = [number substringWithRange:NSMakeRange(1, 2)];
                }else if ([[number substringToIndex:2] isEqualToString:@"02"]) {
                    prefix = [number substringWithRange:NSMakeRange(1, 2)];
                }else if ([[number substringToIndex:2] isEqualToString:@"00"]) {
                    if (number.length >= 5) {
                        prefix = [number substringWithRange:NSMakeRange(1, 4)];
                    }
                }else {
                    if (number.length >= 4) {
                        prefix = [number substringWithRange:NSMakeRange(1, 3)];
                    }else{
                        prefix = number;
                    }
                }
            }else{
                prefix = number;
            }

            
            NSString *cityid;
            NSString *provinceid;
            NSString *provinceName = @"";
            NSString *cityName = @"";
            
            FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM Number_0 where number='%@'",prefix]];
            if ([rs next]) {
                cityid = [NSString stringWithFormat:@"%zd",[rs longLongIntForColumn:@"city_id"]];
                provinceid = [NSString stringWithFormat:@"%zd", [rs longLongIntForColumn:@"province_id"]];
            }
            rs = [db executeQuery:[NSString stringWithFormat:@"SELECT name FROM Province where id='%@'",provinceid]];
            if ([rs next]) {
                provinceName = [rs stringForColumn:@"name"];
            }
            
            if (cityid.length) {
                rs = [db executeQuery:[NSString stringWithFormat:@"SELECT name FROM City where id='%@'",cityid]];
                if ([rs next]) {
                    cityName = [rs stringForColumn:@"name"];
                }
            }
            [dicPhoneRecord setObject:[NSString stringWithFormat:@"%@ %@",provinceName,cityName] forKey:@"location"];
            [rs close];
        }else{
            
            if ([number length]>=8) {
                NSString *prefix = [number substringToIndex:3];
                NSString *center = [number substringWithRange:{3,4}];
                
                NSString *cityid;
                NSString *provinceid;
                NSString *provinceName = @"";
                NSString *cityName = @"";
                
                FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM Number_%@ where number='%@'",prefix,center]];
                if ([rs next]) {
                    cityid = [NSString stringWithFormat:@"%zd",[rs longLongIntForColumn:@"city_id"]];
                    provinceid = [NSString stringWithFormat:@"%zd", [rs longLongIntForColumn:@"province_id"]];
                }
                
                rs = [db executeQuery:[NSString stringWithFormat:@"SELECT name FROM Province where id='%@'",provinceid]];
                if ([rs next]) {
                    provinceName = [rs stringForColumn:@"name"];
                }
                if (cityid.length) {
                    rs = [db executeQuery:[NSString stringWithFormat:@"SELECT name FROM City where id='%@'",cityid]];
                    if ([rs next]) {
                        cityName = [rs stringForColumn:@"name"];
                    }
                }
                [dicPhoneRecord setObject:[NSString stringWithFormat:@"%@ %@",provinceName,cityName] forKey:@"location"];
                
                [rs close];
            }else{
                NSString *phoneStr = [self checkPhoneNumberIsMobile:number];
                if (phoneStr) {
                    [dicPhoneRecord setObject:phoneStr forKey:@"location"];
                }
            }
        }
        //不在此时插入数据
//        [self.arrPhoneRecord insertObject:dicPhoneRecord atIndex:0];
//        [self.tableView reloadData];
        [db close];
    }
    
//    [self insertSqlData:dicPhoneRecord];
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    path = [paths objectAtIndex:0];
//    path = [path stringByAppendingPathComponent:@"callrecord.db"];
    path = [path stringByAppendingPathComponent:@"callrecord2.db"];
    db = [FMDatabase databaseWithPath:path];
    
    if (![db open]) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"创建通话记录失败") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil] show];
        return FALSE;
    }else{
        [self insertSqlData:dicPhoneRecord dataBase:db Calltime:timestemp];
    }
    return YES;
}

- (void)insertSqlData:(NSDictionary *)dicPhoneRecord dataBase:(FMDatabase *)db Calltime:(NSString *)calltime
{
    NSMutableString *dataId = [NSMutableString string];
    [dataId appendString:[dicPhoneRecord objectForKey:@"hostnumber"]];
    [dataId appendString:[dicPhoneRecord objectForKey:@"destnumber"]];
    [dataId appendString:[dicPhoneRecord objectForKey:@"calltype"]];
//    NSTimeInterval a = [calltime timeIntervalSince1970];
//    NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
    NSMutableArray *muteArray = [NSMutableArray array];
    [muteArray addObject:dicPhoneRecord];
    //监测数据库中我要需要的表是否已经存在
    NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord"];
    FMResultSet *rs = [db executeQuery:existsSql];
    if ([rs next]) {
        NSInteger count = [rs intForColumn:@"countNum"];
        NSLog(@"The table count: %zd", count);
        if (count == 1) {
            NSLog(@"log_keepers table is existed.");
            //添加记录

            //查询是否包含数据
            
            rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM CallRecord where dataid='%@'",dataId]];
            if ([rs next]) {
                //如果能打开说明已存在,获取数据
                NSString *jsonStr1 = [rs stringForColumn:@"datas"];
                NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
                NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
                muteArray = [NSMutableArray arrayWithArray:dataArray];
                [muteArray insertObject:dicPhoneRecord atIndex:0];
                
                NSData *jsonData2 = [NSJSONSerialization dataWithJSONObject:[muteArray copy] options:NSJSONWritingPrettyPrinted error:nil];
                NSString *jsonStr2 = [[NSString alloc] initWithData:jsonData2 encoding:NSUTF8StringEncoding];

               BOOL isSuccess = [db executeUpdate:[NSString stringWithFormat:@"UPDATE CallRecord SET datas='%@',calltime='%@' where dataid ='%@'", jsonStr2, calltime, dataId]];
                if (!isSuccess) {
                    NSLog(@"更新通话记录失败！%@",dicPhoneRecord);
                }
            }else{
                NSData *jsonData2 = [NSJSONSerialization dataWithJSONObject:muteArray options:NSJSONWritingPrettyPrinted error:nil];
                NSString *jsonStr2 = [[NSString alloc] initWithData:jsonData2 encoding:NSUTF8StringEncoding];
                BOOL isSuccess = [db executeUpdate:@"INSERT INTO CallRecord (datas, calltime, dataid) VALUES (?, ?, ?)", jsonStr2, calltime, dataId];
                if (!isSuccess) {
                    NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
                }
            }
            
//            BOOL success = [db executeUpdate:@"INSERT INTO CallRecord (hostnumber, destnumber, calltime, calltype, location, status) VALUES (?, ?, ?, ?, ?, ?)", [dicPhoneRecord objectForKey:@"hostnumber"], [dicPhoneRecord objectForKey:@"destnumber"], timestemp,[dicPhoneRecord objectForKey:@"calltype"],[dicPhoneRecord objectForKey:@"location"],[dicPhoneRecord objectForKey:@"status"]];
//            if (!success) {
//                NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
//            }
            //return TRUE;
        }
        NSLog(@"log_keepers is not existed.");
        //创建表
        //[membersDB executeUpdate:@"CREATE TABLE PersonList (Name text, Age integer, Sex integer,Phone text, Address text, Photo blob)"];
        
        [db executeUpdate:@"CREATE TABLE CallRecord (datas Text, calltime TimeStamp, dataid text)"];
    }else{
        //添加记录
//        NSInteger a=[calltime timeIntervalSince1970];
//        NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
//        BOOL success = [db executeUpdate:@"INSERT INTO CallRecord (datas, calltime, dataid) VALUES (?, ?, ?)", [dicPhoneRecord objectForKey:@"hostnumber"], [dicPhoneRecord objectForKey:@"destnumber"], timestemp,[dicPhoneRecord objectForKey:@"calltype"],[dicPhoneRecord objectForKey:@"location"],[dicPhoneRecord objectForKey:@"status"]];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[muteArray copy] options:NSJSONWritingPrettyPrinted error:nil];
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        BOOL isSuccess = [db executeUpdate:@"INSERT INTO CallRecord (datas, calltime, dataid) VALUES (?, ?, ?)", jsonStr, calltime, dataId];
        
        if (!isSuccess) {
            NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
        }
    }
    [rs close];
    [db close];
    [self loadPhoneRecord];
}

//- (void)insertSqlData:(NSDictionary *)dicPhoneRecord dataBase:(FMDatabase *)db Calltime:(NSDate *)calltime
//{
//    //监测数据库中我要需要的表是否已经存在
//    NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord" ];
//    FMResultSet *rs = [db executeQuery:existsSql];
//    if ([rs next]) {
//        NSInteger count = [rs intForColumn:@"countNum"];
//        NSLog(@"The table count: %zd", count);
//        if (count == 1) {
//            NSLog(@"log_keepers table is existed.");
//            //添加记录
//            NSInteger a=[calltime timeIntervalSince1970];
//            NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
//            BOOL success = [db executeUpdate:@"INSERT INTO CallRecord (hostnumber, destnumber, calltime, calltype, location, status) VALUES (?, ?, ?, ?, ?, ?)", [dicPhoneRecord objectForKey:@"hostnumber"], [dicPhoneRecord objectForKey:@"destnumber"], timestemp,[dicPhoneRecord objectForKey:@"calltype"],[dicPhoneRecord objectForKey:@"location"],[dicPhoneRecord objectForKey:@"status"]];
//            if (!success) {
//                NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
//            }
//            //return TRUE;
//        }
//        NSLog(@"log_keepers is not existed.");
//        //创建表
//        //[membersDB executeUpdate:@"CREATE TABLE PersonList (Name text, Age integer, Sex integer,Phone text, Address text, Photo blob)"];
//        [db executeUpdate:@"CREATE TABLE CallRecord (hostnumber Text, destnumber Text, calltime TimeStamp, calltype text, location Text, status Integer)"];
//    }else{
//        //添加记录
//        NSInteger a=[calltime timeIntervalSince1970];
//        NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
//        BOOL success = [db executeUpdate:@"INSERT INTO CallRecord (hostnumber, destnumber, calltime, calltype, location, status) VALUES (?, ?, ?, ?, ?, ?)", [dicPhoneRecord objectForKey:@"hostnumber"], [dicPhoneRecord objectForKey:@"destnumber"], timestemp,[dicPhoneRecord objectForKey:@"calltype"],[dicPhoneRecord objectForKey:@"location"],[dicPhoneRecord objectForKey:@"status"]];
//        
//        if (!success) {
//            NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
//        }
//    }
//    [rs close];
//
//}






//- (BOOL)addPhoneRecordWithHostcid:(NSString *)hostcid Destcid:(NSString *)destcid Calltime:(NSDate *)calltime Calltype:(NSString *)calltype {
//    
////    BOOL isCheckResult = YES;
//    
//    NSMutableDictionary *dicPhoneRecord = [[NSMutableDictionary alloc] initWithObjectsAndKeys:calltime,@"calltime",calltype,@"calltype",[self numberFromCid:hostcid],@"hostnumber",[self numberFromCid:destcid],@"destnumber",@0,@"status", nil];  //时间写入记录时不需要转成字符
//    [dicPhoneRecord setObject:@"未知" forKey:@"location"];
//    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"location" ofType:@"db"];
//    
//    FMDatabase *db = [FMDatabase databaseWithPath:path];
//    if (![db open]) {
//        NSLog(@"数据库打开失败！");
//    }else{
//        NSString *number;
//        if ([calltype isEqualToString:@"去电"]) {
//            number = [dicPhoneRecord objectForKey:@"destnumber"];
//        } else {
//            number = [dicPhoneRecord objectForKey:@"hostnumber"];
//        }
//            //NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithDictionary:dicPhoneRecord copyItems:YES];
////        [dicPhoneRecord setObject:@"未知" forKey:@"location"];
//        if ([self isZeroStarted:number]) {
//            NSString *prefix;
//            if ([[number substringToIndex:2] isEqualToString:@"01"]) {
//                prefix = [number substringToIndex:3];
//            }else if ([[number substringToIndex:2] isEqualToString:@"02"]) {
//                prefix = [number substringToIndex:3];
//            } else {
//                prefix = [number substringToIndex:4];
//            }
//            
//            NSString *cityid;
//            NSString *provinceid;
//            
//            FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM number_%@ limit %d,1",@"0",[prefix intValue]-1]];
//            if ([rs next]) {
//                cityid = [NSString stringWithFormat:@"%d",[rs intForColumnIndex:0]];
//            }
//            rs = [db executeQuery:[NSString stringWithFormat:@"SELECT province_id FROM city where _id=%@",cityid]];
//            if ([rs next]) {
//                provinceid = [NSString stringWithFormat:@"%d",[rs intForColumnIndex:0]];
//            }
//            rs = [db executeQuery:[NSString stringWithFormat:@"SELECT province,city FROM province,city where _id=%@ and id=%@",cityid,provinceid]];
//            if ([rs next]) {
//                [dicPhoneRecord setObject:[NSString stringWithFormat:@"%@ %@",[rs stringForColumn:@"province"],[rs stringForColumn:@"city"]] forKey:@"type"];
//            }
//        }else{
//            
//            if ([number length]>=8) {
//                NSString *prefix = [number substringToIndex:3];
//                NSString *center = [number substringWithRange:{3,4}];
//                
//                NSString *cityid;
//                NSString *provinceid;
//                
//                FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM number_%@ limit %@,1",prefix,center]];
//                if ([rs next]) {
//                    cityid = [NSString stringWithFormat:@"%d",[rs intForColumnIndex:0]];
//                }
//                
//                rs = [db executeQuery:[NSString stringWithFormat:@"SELECT province_id FROM city where _id=%@",cityid]];
//                if ([rs next]) {
//                    provinceid = [NSString stringWithFormat:@"%d",[rs intForColumnIndex:0]];
//                }
//                
//                rs = [db executeQuery:[NSString stringWithFormat:@"SELECT province,city FROM province,city where _id=%@ and id=%@",cityid,provinceid]];
//                if ([rs next]) {
//                    [dicPhoneRecord setObject:[NSString stringWithFormat:@"%@ %@",[rs stringForColumn:@"province"],[rs stringForColumn:@"city"]] forKey:@"location"];
//                }
//            }else{
//                NSString *phoneStr = [self checkPhoneNumberIsMobile:number];
//                if (phoneStr) {
//                    [dicPhoneRecord setObject:phoneStr forKey:@"location"];
//                }
//            }
//        }
//        
////        if ([[dicPhoneRecord objectForKey:@"location"] isEqualToString:@"未知"]) {
////            isCheckResult = NO;
////        }
////        if (isCheckResult) {
////            [self.arrPhoneRecord insertObject:dicPhoneRecord atIndex:0];
////            [self.tableView reloadData];
////        }
//        
//        [self.arrPhoneRecord insertObject:dicPhoneRecord atIndex:0];
//        [self.tableView reloadData];
//    }
//    
//    //可通过判断是否为未知来进行网络请求归属地
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    path = [paths objectAtIndex:0];
//    path = [path stringByAppendingPathComponent:@"callrecord.db"];
//    db = [FMDatabase databaseWithPath:path];
//    
//    if (![db open]) {
//        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"创建通话记录失败" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
//        return FALSE;
//        
//    }else{
//        //监测数据库中我要需要的表是否已经存在
//        NSString *existsSql = [NSString stringWithFormat:@"select count(name) as countNum from sqlite_master where type = 'table' and name = '%@'", @"CallRecord" ];
//        FMResultSet *rs = [db executeQuery:existsSql];
//        if ([rs next]) {
//            NSInteger count = [rs intForColumn:@"countNum"];
//            NSLog(@"The table count: %li", count);
//            if (count == 1) {
//                NSLog(@"log_keepers table is existed.");
//                //添加记录
//                NSInteger a=[calltime timeIntervalSince1970];
//                NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
//                BOOL success = [db executeUpdate:@"INSERT INTO CallRecord (hostnumber, destnumber, calltime, calltype, location, status) VALUES (?, ?, ?, ?, ?, ?)", [dicPhoneRecord objectForKey:@"hostnumber"], [dicPhoneRecord objectForKey:@"destnumber"], timestemp,[dicPhoneRecord objectForKey:@"calltype"],[dicPhoneRecord objectForKey:@"location"],[dicPhoneRecord objectForKey:@"status"]];
//                
//                if (!success) {
//                    NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
//                }
//                //return TRUE;
//            }
//            
//            NSLog(@"log_keepers is not existed.");
//            //创建表
//            //[membersDB executeUpdate:@"CREATE TABLE PersonList (Name text, Age integer, Sex integer,Phone text, Address text, Photo blob)"];
//            [db executeUpdate:@"CREATE TABLE CallRecord (hostnumber Text, destnumber Text, calltime TimeStamp, calltype text, location Text, status Integer)"];
//        }else{
//            //添加记录
//            NSInteger a=[calltime timeIntervalSince1970];
//            NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
//            BOOL success = [db executeUpdate:@"INSERT INTO CallRecord (hostnumber, destnumber, calltime, calltype, location, status) VALUES (?, ?, ?, ?, ?, ?)", [dicPhoneRecord objectForKey:@"hostnumber"], [dicPhoneRecord objectForKey:@"destnumber"], timestemp,[dicPhoneRecord objectForKey:@"calltype"],[dicPhoneRecord objectForKey:@"location"],[dicPhoneRecord objectForKey:@"status"]];
//            
//            if (!success) {
//                NSLog(@"添加通话记录失败！%@",dicPhoneRecord);
//            }
//            
//        }
//        
//        [rs close];
//    }
//    return YES;
//}

-(NSString *)checkPhoneNumberIsMobile:(NSString *)phoneNumber
{
    NSString *phoneStr;
    if([phoneNumber isEqualToString:@"10000"] || [phoneNumber isEqualToString:@"10001"]){
        phoneStr = @"中国电信";
    }else if([phoneNumber isEqualToString:@"10010"] || [phoneNumber isEqualToString:@"10011"]){
        phoneStr = @"中国联通";
    }else if([phoneNumber isEqualToString:@"10086"]){
        phoneStr = @"中国移动";
    }else if([phoneNumber isEqualToString:@"10039"]){
        phoneStr = @"分享通讯";
    }else{
        phoneStr = nil;
    }
    return phoneStr;
}

- (void)makeCallAction :(NSNotification *)notification {
    NSString *phoneNumber = notification.object;
    if (phoneNumber) {
        [self callNumber:phoneNumber];
    }
}

- (void)makeUnitysCallAction:(NSNotification *)notification {
    NSString *phoneNumber = notification.object;
    
    if (phoneNumber) {
        [self callUnitysNumber:phoneNumber];
    }
}

- (void)getMaxPhoneCall {
    self.checkToken = YES;
    [SSNetworkRequest getRequest:apiGetMaxmimumPhoneCallTime params:nil success:^(id responseObj) {
        NSLog(@"有数据：%@",responseObj);
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            self.maxPhoneCall = [[[responseObj objectForKey:@"data"]  objectForKey:@"maximumPhoneCallTime"] intValue];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"有异常：%@",[error description]);
    } headers:self.headers];
}

- (void)callingAction:(NSNotification *)notification {
    if (notification.object) {
        NSString *action = notification.object;
        
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        if ([action isEqualToString:@"Hungup"]) {
            self.speakerStatus = NO;
            if(theSipEngine->InCalling())
            theSipEngine->TerminateCall();
            
            //挂断系统的通话界面
            if (kSystemVersionValue >= 10.0 && isUseCallKit) {
                [[UNCallKitCenter sharedInstance]  endCall:nil completion:^(NSError * _Nullable error) {
                }];
            }
            self.callStopTime = [NSDate date];
            self.hostHungup = @"source";
//            [self endingCallOut];
        }else if ([action isEqualToString:@"SwitchSound"]){
            //保存扩音状态,在未接通时修改扩音状态无效,因此保存此状态,在接通时更新.
            if (notification.userInfo) {
                if (notification.userInfo[@"isHandfreeon"]) {
                    self.speakerStatus = [notification.userInfo[@"isHandfreeon"] boolValue];
                }
            }
            NSLog(@"当前扩音状态:%zd", self.speakerStatus);
            //系统扩音状态会自动更新,无法对系统扩音进行操作,因此不做处理
            theSipEngine->SetLoudspeakerStatus(self.speakerStatus);
            
        }else if ([action isEqualToString:@"MuteSound"]){
            if (notification.userInfo) {
                if (notification.userInfo[@"isMuteon"]) {
                    self.muteStatus = [notification.userInfo[@"isMuteon"] boolValue];
                }
            }
            
            //对系统的通话界面进行无声
            if (kSystemVersionValue >= 10.0 && isUseCallKit) {
                [[UNCallKitCenter sharedInstance]  mute:self.muteStatus callUUID:nil completion:^(NSError * _Nullable error) {
                }];
            }else{
                theSipEngine->MuteMic(self.muteStatus);
            }
            
//            self.muteStatus = !self.muteStatus;
//            theSipEngine->MuteMic(self.muteStatus);
        }else if ([action isEqualToString:@"Answer"]){
            //选择最后一条，更新为
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *path = [paths objectAtIndex:0];
            
//            path = [path stringByAppendingPathComponent:@"callrecord.db"];
            path = [path stringByAppendingPathComponent:@"callrecord2.db"];
            
            FMDatabase *db = [FMDatabase databaseWithPath:path];
            if (![db open]) {
                [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"创建通话记录失败") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil] show];
            }else{
                //查找出错
//                FMResultSet *rs = [db executeQuery:@"select * from CallRecord order by calltime asc limit 0,1"];
                //降序,更新最后一条数据
                FMResultSet *rs = [db executeQuery:@"select * from CallRecord order by calltime desc limit 0,1"];
                if ([rs next]) {
                    //如果能打开说明已存在,获取数据
                    NSString *jsonStr1 = [rs stringForColumn:@"datas"];
                    NSData *jsonData1 = [jsonStr1 dataUsingEncoding:NSUTF8StringEncoding];
                    NSArray *dataArray=[NSJSONSerialization JSONObjectWithData:jsonData1 options:NSJSONReadingAllowFragments error:nil];
                    NSMutableArray *muteArray = [NSMutableArray arrayWithArray:dataArray];
                    NSMutableDictionary *dictRecord;
                    if (dataArray.count) {
                        dictRecord = [NSMutableDictionary dictionaryWithDictionary:dataArray.firstObject];
                    }
                    [dictRecord setObject:@1 forKey:@"status"];
                    [muteArray replaceObjectAtIndex:0 withObject:dictRecord];
                    
                    NSData *jsonData2 = [NSJSONSerialization dataWithJSONObject:[muteArray copy] options:NSJSONWritingPrettyPrinted error:nil];
                    NSString *jsonStr2 = [[NSString alloc] initWithData:jsonData2 encoding:NSUTF8StringEncoding];
                    [db executeUpdate:[NSString stringWithFormat:@"update CallRecord SET datas='%@' WHERE calltime='%@'", jsonStr2, [rs stringForColumn:@"calltime"]]];
//                    BOOL isSuccess = [db executeUpdate:@"UPDATE CallRecord set datas='%@' calltime='%@' where dataid ='%@'", jsonStr2, timestemp, dataId];
//                    if (!isSuccess) {
//                        NSLog(@"更新通话记录失败！%@",dicPhoneRecord);
//                    }
//                    [db executeUpdate:@"update CallRecord set status=1 where calltime=?",[rs stringForColumn:@"calltime"]];
                    [rs close];
                    [db close];
                }
                
            }
            [self loadPhoneRecord];
            [self.tableView reloadData];

            theSipEngine->AnswerCall();
            theSipEngine->StopRinging();
        }else if ([action isEqualToString:@"Refuse"]){
            theSipEngine->TerminateCall();
        }
    }
}

-(void) OnNetworkQuality:(int)ms {
    //网络质量提示？
}

-(void)OnSipEngineState:(SipEngineState)code {
    if (code==0) {
        //
    } else {
        //
    }
}


//电话拨打进来
- (void)InComingCallWithCallKitName:(NSString *)name PhoneNumber:(NSString *)phoneNumber
{
    if (!callCenter) {
        callCenter=[UNCallKitCenter sharedInstance];
    }
    
    UNContact * contact = [[UNContact alloc]init];
    contact.phoneNumber= phoneNumber;
    contact.displayName= name;
    contact.uniqueIdentifier= @"";
    
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUUID * callUUID=[[UNCallKitCenter sharedInstance] reportIncomingCallWithContact:contact completion:^(NSError * _Nullable error)
                           {
                               if (error == nil) {
                                   NSLog(@"%s success", __func__);
                               }else{
                                   NSLog(@"arror %@", error);
                               }
                           }];
        NSLog(@"callUUID==%@", callUUID);
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
    });
    
    kWeakSelf
    callCenter.actionNotificationBlock = ^(CXCallAction *action, UNCallActionType actionType){
        switch (actionType) {
            case UNCallActionTypeAnswer:
            {
                weakSelf.callCominginVC                    = [[CallComingInViewController alloc] init];
                weakSelf.callCominginVC.nameStr            = [weakSelf checkLinkNameWithPhoneStr:name];
                weakSelf.callCominginVC.isPresentInCallKit = YES;
                [weakSelf.navigationController presentViewController:weakSelf.callCominginVC animated:NO completion:^{
                }];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSNotification *noti = [[NSNotification alloc] initWithName:@"CallingAction" object:@"Answer" userInfo:nil];
                    [weakSelf callingAction:noti];
                });
                
//                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
//                theSipEngine->AnswerCall();
//                theSipEngine->StopRinging();
            }
                break;
            case UNCallActionTypeEnd:
            {
                //对APP通话进行挂断操作
                if (weakSelf.callCominginVC) {
                    [weakSelf.callCominginVC endCallPhone];
                }
                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                if(theSipEngine->InCalling())
                    theSipEngine->TerminateCall();
                weakSelf.callStopTime = [NSDate date];
                weakSelf.hostHungup = @"source";
            }
                break;
            case UNCallActionTypeMute:
            {
                //对APP通话进行无声操作
                if ([action isKindOfClass:[CXSetMutedCallAction class]]) {
                    CXSetMutedCallAction *muteAction = (CXSetMutedCallAction *)action;
                    //发送是否无声的操作
                    if (weakSelf.callCominginVC) {
                        weakSelf.muteStatus = muteAction.isMuted;
                        [weakSelf.callCominginVC setUpMuteButtonStatu:muteAction.isMuted];
                    }
                }

            }
                break;
            case UNCallActionTypeHeld:
            {
                
            }
                break;
            default:
                break;
        }
        
    };
 
}


-(void) OnNewCall:(CallDir)dir
 withPeerCallerID:(NSString*)cid
        withVideo:(BOOL)video_call{
    NSLog(@"新呼叫");
//    NSString *msg = @"";
    NSString *newcid;
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    
    if (dir == CallIncoming){
//        msg = [NSString stringWithFormat:@"新来电 %@",cid];
        //去掉“+”
        if ([cid containsString:@"+"]) {
            newcid = [cid stringByReplacingOccurrencesOfString:@"+" withString:@""];
            cid = newcid;
        }
        //去掉86
        if ([[cid substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"86"]) {
            newcid = [cid substringFromIndex:2];
            cid = newcid;
        }
        
        if (kSystemVersionValue >= 10.0 && isUseCallKit) {
            [self InComingCallWithCallKitName:[self checkLinkNameWithPhoneStr:cid] PhoneNumber:cid];
        }else{
//            msg = [NSString stringWithFormat:@"新来电 %@",cid];
//            //去掉“+”
//            if ([cid containsString:@"+"]) {
//                newcid = [cid stringByReplacingOccurrencesOfString:@"+" withString:@""];
//                cid = newcid;
//            }
//            //去掉86
//            if ([[cid substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"86"]) {
//                newcid = [cid substringFromIndex:2];
//                cid = newcid;
//            }
            self.callCominginVC = [[CallComingInViewController alloc] init];
            self.callCominginVC.nameStr = [self checkLinkNameWithPhoneStr:cid];
            [self.navigationController presentViewController:self.callCominginVC animated:YES completion:nil];
            
        }
        [self addPhoneRecordWithHostcid:cid Destcid:[userdata objectForKey:@"Tel"] Calltime:[NSDate date] Calltype:@"来电"];
        
        /*
        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
        theSipEngine->start*/
        //[mBtnDial setTitle:@"接听" forState:UIControlStateNormal];
    }else{
//        msg = [NSString stringWithFormat:@"新去电 %@",cid];
        [self addPhoneRecordWithHostcid:[userdata objectForKey:@"Tel"] Destcid:cid Calltime:[NSDate date] Calltype:@"去电"];
    }
    //    [mStatus setText:msg];
}

-(void) OnCallProcessing{
    //    NSLog(@"正在接续...");
    //    [mStatus setText:@"正在接续..."];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在呼叫...")];
}

/*对方振铃*/
-(void) OnCallRinging{
//        NSLog(@"对方振铃...");
    //    [mStatus setText:@"对方振铃..."];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"对方振铃...")];
}

/*呼叫接通*/
-(void) OnCallStreamsRunning:(bool)is_video_call{
        NSLog(@"接通...");
    //    [mStatus setText:@"呼叫接通"];
    //在接通时更新扩音状态
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    theSipEngine->SetLoudspeakerStatus(self.speakerStatus);
    theSipEngine->MuteMic(self.muteStatus);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在通话")];
}

-(void) OnCallMediaStreamsConnected:(MediaTransMode)mode{
    //    NSLog(@"接通...");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在呼叫...")];
    //    [mStatus setText:@"媒体接通"];
}

-(void) OnCallResume {
    NSLog(@"继续通话");
}

-(void) onCallResumeByRemote {
    //远程
    NSLog(@"对方继续通话");
}

-(void) OnCallPaused {
    NSLog(@"暂停通话");
}

-(void) onCallPausedByRemote {
    NSLog(@"对方暂停通话");
}

-(void) OnCallRemotePaused {
    NSLog(@"暂停通话");
}

/*呼叫接通知识*/
-(void) OnCallConnected{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"正在通话")];
}

/*话单*/
-(void) OnCallReport:(void*)report{
    
}

/*呼叫结束*/
-(void) OnCallEnded{
        NSLog(@"结束通话");
    //    [mStatus setText:@"结束通话"];
    
    [self loadPhoneRecord];
    self.speakerStatus = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingMessage" object:INTERNATIONALSTRING(@"通话结束")];
    /*
    //移除来电页面
    if (self.callCominginVC) {
        [self.callCominginVC dismissViewControllerAnimated:YES completion:nil];
    }*/
}

/*呼叫失败，并返回错误代码，代码对应的含义，请参考common_types.h*/
-(void) OnCallFailed:(CallErrorCode) error_code{
    NSLog([NSString stringWithFormat:@"呼叫错误, 代码 %d",error_code],nil);
    [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"错误提示") message:[NSString stringWithFormat:@"%@", INTERNATIONALSTRING(@"呼叫异常,请确认网络或账号正常")] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
    //    [mStatus setText:[NSString stringWithFormat:@"呼叫错误, 代码 %d",error_code]];
    
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
-(void)doRegister{
    SipEngine *theSipEngine = [SipEngineManager getSipEngine];
    
    if(theSipEngine->AccountIsRegstered())
    {
        theSipEngine->DeRegisterSipAccount();
        __block SipEngine *callEngine = theSipEngine;
        
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetSecrityConfig params:nil success:^(id responseObj) {
            NSLog(@"有数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if (responseObj[@"data"][@"VswServer"]) {
                    [VSWManager shareManager].vswIp = responseObj[@"data"][@"VswServer"][@"Ip"];
                    [VSWManager shareManager].vswPort = [responseObj[@"data"][@"VswServer"][@"Port"] intValue];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Ip"] forKey:@"VSWServerIp"];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Port"] forKey:@"VSWServerPort"];
                }
                
                NSString *secpwd = [super md5:[[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"] stringByAppendingString:@"voipcc2015"]];
 
                NSString *thirdpwd = [super md5:secpwd];
                
                NSString *userName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] objectForKey:@"Tel"];

                
                self.outIP = [[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"];
                
                callEngine->SetEnCrypt(NO, NO);
                //IP地址
                                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                //域名
//                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [@"asterisk.unitoys.com" UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
            
            
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"有异常：%@",[error description]);
        } headers:self.headers];
        
    }else{

        __block SipEngine *callEngine = theSipEngine;
        
        self.checkToken = YES;
        [self getBasicHeader];
        [SSNetworkRequest getRequest:apiGetSecrityConfig params:nil success:^(id responseObj) {
            NSLog(@"有数据：%@",responseObj);
            
            
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                if (responseObj[@"data"][@"VswServer"]) {
                    [VSWManager shareManager].vswIp = responseObj[@"data"][@"VswServer"][@"Ip"];
                    [VSWManager shareManager].vswPort = [responseObj[@"data"][@"VswServer"][@"Port"] intValue];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Ip"] forKey:@"VSWServerIp"];
                    [[NSUserDefaults standardUserDefaults] setObject:responseObj[@"data"][@"VswServer"][@"Port"] forKey:@"VSWServerPort"];
                }
                
                NSString *secpwd = [super md5:[[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"] stringByAppendingString:@"voipcc2015"]];
            /*
            secpwd = [super md5:@"e38632c0f035e45efe57125bd0ebe8cevoipcc2015"];*/
            //去年替换方案
            
                NSString *thirdpwd = [super md5:secpwd];
            
                NSString *userName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] objectForKey:@"Tel"];
            //[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"PublicPassword"]
            
            //callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String],"", "121.46.3.20", 65061,1800);
                
                self.outIP = [[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"];
                
//                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String],"", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue],1800);
                callEngine->SetEnCrypt(NO, NO);
                //IP地址
                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskIp"] UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                //域名
//                callEngine->RegisterSipAccount([userName UTF8String], [thirdpwd UTF8String], "", [@"asterisk.unitoys.com" UTF8String], [[[[responseObj objectForKey:@"data"] objectForKey:@"Out"] objectForKey:@"AsteriskPort"] intValue]);
                
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
            }
            
            
            
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"有异常：%@",[error description]);
        } headers:self.headers];
        
        /*
         #define CRYPT
         
         #ifdef CRYPT
         theSipEngine->RegisterSipAccount([@"18850161016" UTF8String], [@"18850161016" UTF8String],"", "121.46.3.20", 65061,1800);
         #else
         theSipEngine->RegisterSipAccount([@"18850161016" UTF8String], [@"18850161016" UTF8String],"", "121.46.3.20", 65060,1800);
         #endif */
    }
}

/*帐号注册状态反馈, 失败返回错误代码 代码对应的含义，请参考common_types.h*/
-(void) OnRegistrationState:(RegistrationState) code
              withErrorCode:(RegistrationErrorCode) e_errno{
    
    NSString *msg=@"";
    
    if(code == 1){
        msg = @"正在注册...";
        [SipEngineManager instance].resignStatue = 0;
        //        [mBtnRegister setTitle:@"注册中" forState:UIControlStateNormal];
    }else if(code == 2){
        msg = @"注册成功！";
        [SipEngineManager instance].resignStatue = 1;
        //        [mBtnRegister setTitle:@"注销" forState:UIControlStateNormal];
    }else if(code == 3){
        msg = @"您的账号已注销";
        [SipEngineManager instance].resignStatue = 0;
        //        [mBtnRegister setTitle:@"注册" forState:UIControlStateNormal];
    }else if(code == 4){
        msg = [NSString stringWithFormat:@"注册失败，错误代码 %d",e_errno];
        [SipEngineManager instance].resignStatue = 0;
        //        [mBtnRegister setTitle:@"注册" forState:UIControlStateNormal];
    }
    
    //    [mStatus setText:msg];
    NSLog(@"注册状态：%@",msg);
}

/*
- (void)normalCall {
    if (self.phoneNumber) {
        NSString *num = [[NSString alloc] initWithFormat:@"telprompt://%@",self.phoneNumber]; //而这个方法则打电话前先弹框  是否打电话 然后打完电话之后回到程序中 网上说这个方法可能不合法 无法通过审核
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:num]];
        
        self.typeView.hidden = YES;
    }
    
    
    
}

- (void)networkCall {
    
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    if (storyboard) {
        
        
        CallingViewController *callingViewController = [storyboard instantiateViewControllerWithIdentifier:@"callingViewController"];
        if (callingViewController) {
            self.typeView.hidden = YES;
            callingViewController.lblCallingInfo.text = self.phoneNumber;
            [self presentViewController:callingViewController animated:YES completion:^{
                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                
                theSipEngine->MakeCall([[NSString stringWithFormat:@"971%@#60",self.phoneNumber] UTF8String],false,NULL);
            }];
        }
    }
}*/



- (void)showOperation {
    
    if (self.callView) {
        //重置拨打图标
        [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pushon"] forState:UIControlStateNormal];
        
        [self.callView setHidden:NO];
        [self.tabBarController.tabBar bringSubviewToFront:self.callView];
    }else{
        // Instantiate the nib content without any reference to it.
        NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"PhoneOperationPad" owner:nil options:nil];
        
        // Find the view among nib contents (not too hard assuming there is only one view in it).
        PhoneOperationPad *callView = [nibContents lastObject];
        
        [callView setFrame:self.tabBarController.tabBar.bounds];
        //callView.deleteNumberBlock
        callView.hidden = NO;
        [self.tabBarController.tabBar addSubview:callView];
        self.callView = callView;
//        [self.tabBarController.tabBar bringSubviewToFront:self.callView];
        kWeakSelf
        self.callView.deleteNumberBlock = ^(){
            if (weakSelf.phonePadView) {
                if (weakSelf.phonePadView.inputedPhoneNumber.length>1) {
                    weakSelf.phonePadView.inputedPhoneNumber = [weakSelf.phonePadView.inputedPhoneNumber substringToIndex:weakSelf.phonePadView.inputedPhoneNumber.length-1];
                    
                    weakSelf.lblPhoneNumber.text = weakSelf.phonePadView.inputedPhoneNumber;
                    
                }else{
                    weakSelf.phonePadView.inputedPhoneNumber = @"";
                    [weakSelf.segmentType setHidden:NO];
                    
                    if (weakSelf.lblPhoneNumber) {
                        weakSelf.lblPhoneNumber.text = nil;
                        [weakSelf.lblPhoneNumber setHidden:YES];
                    }
                    
                    if (weakSelf.callView.hidden==NO) {
                        weakSelf.callView.hidden = YES;
                    }
                    
                    
                }
                NSLog(@"lblPhoneNumber------%@", weakSelf.lblPhoneNumber.text);
                if (weakSelf.phonePadView.inputedPhoneNumber.length) {
                    //搜索电话并展示
                    [weakSelf searchInfoWithString:weakSelf.lblPhoneNumber.text];
                    weakSelf.isSearchStatu = YES;
                    [weakSelf.tableView reloadData];
                }else{
                    weakSelf.isSearchStatu = NO;
                    [weakSelf.tableView reloadData];
                }

            }
        };
        
        self.callView.calloutBlock = ^(){
            [self standardCall];
        };
        
        self.callView.switchStatusBlock = ^(BOOL hidden) {
            if (hidden) {
                //开始加载谁
                [self switchNumberPad:YES];
//                [self.phonePadView setHidden:YES];
                [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pulloff"] forState:UIControlStateNormal];
 
            }else{
                
//                [self.phonePadView setHidden:NO];
                [self switchNumberPad:NO];
                [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pushon"] forState:UIControlStateNormal];
                
            }
            
        };
    }
    /*
    NSLog(@"数据：%@",weakSelf.view);
    UIView *callView = [[UIView alloc] initWithFrame:CGRectMake(0, weakSelf.tableView.bounds.size.height-30, 100, 30)];
    callView.backgroundColor = [UIColor redColor];
    
    [weakSelf.view addSubview:callView];*/
}

- (void)standardCall {
    NSString *strPhoneNumber = self.phonePadView.inputedPhoneNumber;
//    self.phonePadView.inputedPhoneNumber = nil;
//    self.lblPhoneNumber.text = nil;
////    [self showOperation];
//    self.lblPhoneNumber.hidden = YES;
//    self.segmentType.hidden = NO;
//    self.callView.hidden = YES;
//    //清空搜索状态
//    self.isSearchStatu = NO;
//    [self.searchLists removeAllObjects];
    
    
//    [self callNumber:[self formatPhoneNum:strPhoneNumber]];
    
    //展示拨打电话选项
    [self selectCallPhoneType:[self formatPhoneNum:strPhoneNumber]];
    

}

- (void)selectCallPhoneType:(NSString *)phoneNumber
{
    //电话记录，拨打电话
    if (!self.callActionView){
        self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue)];
        
//        [self.view addSubview:self.callActionView];
    }
    
    __weak typeof(self) weakSelf = self;
    
    self.callActionView.cancelBlock = ^(){

        [weakSelf.callActionView hideActionView];
    };
    
    self.callActionView.actionBlock = ^(NSInteger callType){

        [weakSelf.callActionView hideActionView];
        
        weakSelf.phonePadView.inputedPhoneNumber = nil;
        weakSelf.lblPhoneNumber.text = nil;
    //    [self showOperation];
        weakSelf.lblPhoneNumber.hidden = YES;
        weakSelf.segmentType.hidden = NO;
        weakSelf.callView.hidden = YES;
        //清空搜索状态
        weakSelf.isSearchStatu = NO;
        [weakSelf.searchLists removeAllObjects];
        [weakSelf.tableView reloadData];
        
        if (callType==1) {
            //网络电话
            //电话记录，拨打电话
            [weakSelf callNumber:phoneNumber];
        }else if (callType==2){
            //手环电话
            if ([BlueToothDataManager shareManager].isRegisted) {
                //电话记录，拨打电话
                [weakSelf callUnitysNumber:phoneNumber];
            } else {
                HUDNormal(INTERNATIONALSTRING(@"手环内sim卡未注册或已掉线"))
            }
        }
    };

    [self.callActionView showActionView];
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

- (void)callNumber :(NSString *)strNumber {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    
    if (storyboard) {
        if (!strNumber) {
            self.phoneNumber= self.phonePadView.inputedPhoneNumber;
        }else{
            self.phoneNumber = strNumber;
        }
        self.calledTelNum = [NSString stringWithFormat:@"981%@",self.phoneNumber];
        
        //获取最大通话时长后再拨打
        [SSNetworkRequest getRequest:apiGetMaxmimumPhoneCallTime params:nil success:^(id responseObj) {
            NSLog(@"有数据：%@",responseObj);
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                
                CallingViewController *callingViewController = [storyboard instantiateViewControllerWithIdentifier:@"callingViewController"];
                if (callingViewController) {
                    self.callStartTime = [NSDate date];
                    callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
                    [self presentViewController:callingViewController animated:YES completion:^{
                        self.maxPhoneCall = [[[responseObj objectForKey:@"data"]  objectForKey:@"maximumPhoneCallTime"] intValue];
                        SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                        callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
                        theSipEngine->MakeCall([[NSString stringWithFormat:@"981%@#%d",[self formatPhoneNum:self.phoneNumber],self.maxPhoneCall] UTF8String],false,NULL);
                        
                    }];
                }
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                NSLog(@"获取最大时长失败");
                //                    HUDNormal(responseObj[@"msg"])
                HUDNormal(INTERNATIONALSTRING(@"获取通话时长失败"))
            }
        } failure:^(id dataObj, NSError *error) {
            NSLog(@"有异常：%@",[error description]);
            HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        } headers:self.headers];
        
    }
    
}

- (void)callUnitysNumber :(NSString *)strNumber {
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        return;
    }
    
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    if (storyboard) {
        if (!strNumber) {
            self.phoneNumber= self.phonePadView.inputedPhoneNumber;
        }else{
            self.phoneNumber = strNumber;
        }
        if (self.phoneNumber) {
            self.calledTelNum = [NSString stringWithFormat:@"986%@",self.phoneNumber];
        }
        
        CallingViewController *callingViewController = [storyboard instantiateViewControllerWithIdentifier:@"callingViewController"];
        if (callingViewController) {
            self.callStartTime = [NSDate date];
            callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
            [self presentViewController:callingViewController animated:YES completion:^{
                SipEngine *theSipEngine = [SipEngineManager getSipEngine];
                callingViewController.lblCallingInfo.text = [self checkLinkNameWithPhoneStr:self.phoneNumber];
                if ([VSWManager shareManager].callPort) {
                    theSipEngine->MakeCall([[NSString stringWithFormat:@"986%@%@",[VSWManager shareManager].callPort, [self formatPhoneNum:self.phoneNumber]] UTF8String],false,NULL);
                }else{
                    HUDNormal(INTERNATIONALSTRING(@"呼叫失败"))
                }
            }];
        }
    }
}

- (void)endingCallOut {
    self.checkToken = YES;
    int dat = [self.callStopTime timeIntervalSinceReferenceDate]-[self.callStartTime timeIntervalSinceReferenceDate];
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[userdata objectForKey:@"Tel"],@"DeviceName",self.calledTelNum,@"calledTelNum",[self formatTime:self.callStartTime],@"callStartTime", [self formatTime:self.callStopTime],@"callStopTime",[NSString stringWithFormat:@"%d",dat],@"callSessionTime",self.outIP,@"callSourceIp",self.outIP,@"callServerIp",self.hostHungup,@"acctterminatedirection",nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiAddSpeakRecord params:params success:^(id responseObj) {

        
        NSLog(@"查询到的记录添加：%@",responseObj);
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
//            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            NSLog(@"通话记录添加成功");
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
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

- (void)switchNumberPad :(BOOL)hidden {
    
    [self.tableView setNeedsLayout];
    [self.tableView layoutIfNeeded];
    
    if (hidden) {
        NSLog(@"关闭键盘");
        [self.phonePadView setFrame:CGRectMake(0, kScreenHeightValue - 64 - 49, self.phonePadView.frame.size.width, 0)];
        self.numberPadStatus = YES;
    }else{
        NSLog(@"打开键盘");
        [self.phonePadView setFrame:CGRectMake(0, kScreenHeightValue - 64 - 49 - 225, self.phonePadView.frame.size.width, 225)];
        
        self.numberPadStatus = NO;
    }
    
    self.callView.isPadHidden = self.numberPadStatus;
    
//    [self.tableView needsUpdateConstraints];
    
}


- (IBAction)switchOperation:(id)sender {
    
    if (self.callActionView)  [self.callActionView hideActionView]; //切换过程中隐藏电话拨号的弹出面板
    
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    self.phoneOperation = seg.selectedSegmentIndex;
    
    if (seg.selectedSegmentIndex==0) {
        //开始加载
        [self.btnWriteMessage setHidden:YES];
        
        [self.phonePadView setHidden:NO];
        [self switchNumberPad:NO];
        [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pulloff"] forState:UIControlStateNormal];
        //点击拨打按钮时tabbarItem状态更新
        [self.navigationController.tabBarItem setImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
        [self.navigationController.tabBarItem setSelectedImage:[UIImage imageNamed:@"tel_numberpad_pushon"]];
        
        if ([self.tableView.mj_header isRefreshing]) {
            [self.tableView.mj_header endRefreshing];
        }
        if ([self.tableView.mj_footer isRefreshing]) {
            [self.tableView.mj_footer endRefreshing];
        }
        self.tableView.mj_header = nil;
        self.tableView.mj_footer = nil;
    }else{
        if(self.callView){
            [self.callView setHidden:YES];
        }
        [self.btnWriteMessage setHidden:NO];
        
        [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pushon"] forState:UIControlStateNormal];
        [self.phonePadView setHidden:YES];
        
        self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
//            self.arrMessageRecord = nil;
            self.page = 1;
            [self.tableView.mj_footer resetNoMoreData];
            [self loadMessage];
        }];
        
        //刷新尾部
        self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreMessage)];
        //如果数据不够则隐藏
        if (!_arrMessageRecord || _arrMessageRecord.count < 20) {
            self.tableView.mj_footer.hidden = YES;
        }else{
            self.tableView.mj_footer.hidden = NO;
        }
    }
    [self.tableView reloadData];
}

- (IBAction)writeMessage:(id)sender {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    NewMessageViewController *newMessageViewController = [mainStory instantiateViewControllerWithIdentifier:@"newMessageViewController"];
    if (newMessageViewController) {
        //writeMessageViewController.destNumber = [dicPackage objectForKey:@"PackageId"];
        [self.navigationController pushViewController:newMessageViewController animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.phoneOperation==0) {
//        return self.arrPhoneRecord.count;
        if (self.isSearchStatu && self.lblPhoneNumber.text) {
            return self.searchLists.count;
        }else{
            return self.arrPhoneRecord.count;
        }
    }else{
        return self.arrMessageRecord.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.phoneOperation==0) {
        if (self.isSearchStatu && self.lblPhoneNumber.text) {
            id model;
            if ([self.searchLists count] > indexPath.row ) {
                model = self.searchLists[indexPath.row];
            }
            if ([model isKindOfClass:[ContactModel class]]) {
                //展示搜索信息
                SearchContactsCell *cell = [tableView dequeueReusableCellWithIdentifier:searchContactsCellID];
                [cell updateCellWithModel:model HightText:self.lblPhoneNumber.text];
                return cell;
            }else{
                PhoneRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PhoneRecordCell"];
                NSDictionary *dicPhoneRecord = (NSDictionary *)model;
                cell.lblCallTime.text = [self compareCurrentTimeString:[dicPhoneRecord objectForKey:@"calltime"]];
//                cell.lblPhoneType.text = [dicPhoneRecord objectForKey:@"type"];
                [cell.lblPhoneNumber setTextColor:[UIColor blackColor]];
                NSMutableString *bottomStr = [NSMutableString string];
                if ([[dicPhoneRecord objectForKey:@"calltype"] isEqualToString:@"来电"]) {
                    [cell.ivStatus setImage:[UIImage imageNamed:@"tel_callin"]];
                    
                    NSString *phoneNum = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
                    
//                    cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
                    if (![(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"] containsString:phoneNum]) {
                        [bottomStr appendString:(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"]];
                        [bottomStr appendString:@"  "];
                        cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
                    }else{
                        NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:phoneNum attributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
                        NSRange range = [phoneNum rangeOfString:self.lblPhoneNumber.text];
                        if (range.length) {
                            [attriStr setAttributes:@{NSForegroundColorAttributeName : [UIColor blueColor]} range:range];
                        }
                        cell.lblPhoneNumber.attributedText = attriStr;
                    }
                    
                    if ([cell.lblCallTime.text isEqualToString:@"刚刚"]) {
                        NSLog(@"有了：%@",dicPhoneRecord);
                    }
//                    if ([[dicPhoneRecord objectForKey:@"status"] intValue]==0){  //如果未接听则显示红色
//                        [cell.lblPhoneNumber setTextColor:[UIColor redColor]];
//                    }
                }else{
                    [cell.ivStatus setImage:[UIImage imageNamed:@"tel_callout"]];
                    
                    
                    NSString *phoneNum = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
                    
//                    cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
                    if (![(NSString *)[dicPhoneRecord objectForKey:@"destnumber"] containsString:phoneNum]) {
                        [bottomStr appendString:(NSString *)[dicPhoneRecord objectForKey:@"destnumber"]];
                        [bottomStr appendString:@"  "];
                        cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
                    }else{
                        NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:phoneNum attributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
                        NSRange range = [phoneNum rangeOfString:self.lblPhoneNumber.text];
                        if (range.length) {
                            [attriStr setAttributes:@{NSForegroundColorAttributeName : [UIColor blueColor]} range:range];
                        }
                        cell.lblPhoneNumber.attributedText = attriStr;
                    }
                }
                [bottomStr appendString:[dicPhoneRecord objectForKey:@"location"]];
                NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:bottomStr attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
                NSRange range = [bottomStr rangeOfString:self.lblPhoneNumber.text];
                if (range.length) {
                    [attriStr setAttributes:@{NSForegroundColorAttributeName : [UIColor blueColor]} range:range];
                }
                cell.lblPhoneType.attributedText = attriStr;
                return cell;

            }
        }else{
            PhoneRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PhoneRecordCell"];
            NSArray *records = [self.arrPhoneRecord objectAtIndex:indexPath.row];
            NSDictionary *dicPhoneRecord;
            if (records.count) {
                dicPhoneRecord = records[0];
            }
            NSString *phoneCount;
            if (records.count > 1) {
                phoneCount = [NSString stringWithFormat:@" (%zd)", records.count];
            }
//            NSDictionary *dicPhoneRecord = [self.arrPhoneRecord objectAtIndex:indexPath.row];
            cell.lblCallTime.text = [self compareCurrentTimeString:[dicPhoneRecord objectForKey:@"calltime"]];
            cell.lblPhoneType.text = [dicPhoneRecord objectForKey:@"type"];
            [cell.lblPhoneNumber setTextColor:[UIColor blackColor]];
            
            NSMutableString *bottomStr = [NSMutableString string];
            
            if ([[dicPhoneRecord objectForKey:@"calltype"] isEqualToString:@"来电"]) {
                [cell.ivStatus setImage:[UIImage imageNamed:@"tel_callin"]];
                NSString *phoneStr = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"hostnumber"]];
                if (phoneCount) {
                    phoneStr = [phoneStr stringByAppendingString:[NSString stringWithFormat:@"%@", phoneCount]];
                }
                
                cell.lblPhoneNumber.text = phoneStr;
                if (![(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"] containsString:cell.lblPhoneNumber.text] && ![(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"] isEqualToString:@"anonymous"]) {
                    [bottomStr appendString:(NSString *)[dicPhoneRecord objectForKey:@"hostnumber"]];
                    [bottomStr appendString:@"  "];
                }
                
                if ([cell.lblCallTime.text isEqualToString:@"刚刚"]) {
                    NSLog(@"有了：%@",dicPhoneRecord);
                }
                if ([[dicPhoneRecord objectForKey:@"status"] intValue] == 0){  //如果未接听则显示红色
                    [cell.lblPhoneNumber setTextColor:[UIColor redColor]];
                }else{
                    [cell.lblPhoneNumber setTextColor:[UIColor blackColor]];
                }
            }else{
                [cell.ivStatus setImage:[UIImage imageNamed:@"tel_callout"]];
                NSString *phoneStr = [self checkLinkNameWithPhoneStr:[dicPhoneRecord objectForKey:@"destnumber"]];
                if (phoneCount) {
                    phoneStr = [phoneStr stringByAppendingString:[NSString stringWithFormat:@"%@", phoneCount]];
                }
                cell.lblPhoneNumber.text = phoneStr;
                if (![(NSString *)[dicPhoneRecord objectForKey:@"destnumber"] containsString:cell.lblPhoneNumber.text]) {
                    [bottomStr appendString:(NSString *)[dicPhoneRecord objectForKey:@"destnumber"]];
                    [bottomStr appendString:@"  "];
                }
            }
            [bottomStr appendString:[dicPhoneRecord objectForKey:@"location"]];
            cell.lblPhoneType.text = bottomStr;
            return cell;
        }

    }else{
        MessageRecordCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"MessageRecordCell"];
        NSDictionary *dicMessageRecord = [self.arrMessageRecord objectAtIndex:indexPath.row];
        
        if ([dicMessageRecord[@"To"] isEqualToString:self.userInfo[@"Tel"]]) {
//            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicMessageRecord objectForKey:@"Fm"]];
            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStrMergeGroupName:[dicMessageRecord objectForKey:@"Fm"]];
//            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStrNoGroupName:[dicMessageRecord objectForKey:@"Fm"]];
        } else {
//            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStr:[dicMessageRecord objectForKey:@"To"]];
            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStrMergeGroupName:[dicMessageRecord objectForKey:@"To"]];
//            cell.lblPhoneNumber.text = [self checkLinkNameWithPhoneStrNoGroupName:[dicMessageRecord objectForKey:@"To"]];
        }
        
        NSString *textStr = [NSString stringWithFormat:@"%@ >", [self compareCurrentTime:[self convertDate:[dicMessageRecord objectForKey:@"SMSTime"]]]];
        cell.lblMessageDate.text = textStr;
        cell.lblContent.text = [dicMessageRecord objectForKey:@"SMSContent"];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.phoneOperation==0) {
        return 60;
    }else{
        return 80;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.phoneOperation==0) {
        if (self.isSearchStatu && self.lblPhoneNumber.text) {
            //通过点击联系人拨打电话
            id contacts;
            if ([self.searchLists count] > indexPath.row ) {
                contacts = self.searchLists[indexPath.row];
            }
            
            if ([contacts isKindOfClass:[ContactModel class]]) {
                ContactModel *model = (ContactModel *)contacts;
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
                if (storyboard) {
                    
                    ContactsDetailViewController *contactsDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"contactsDetailViewController"];
                    if (contactsDetailViewController) {
                        NSLog(@"联系结果：%@",model);
                        //重置状态
                        [self.callActionView hideActionView];
                        
                        self.phonePadView.inputedPhoneNumber = nil;
                        self.lblPhoneNumber.text = nil;
                        //    [self showOperation];
                        self.lblPhoneNumber.hidden = YES;
                        self.segmentType.hidden = NO;
                        self.callView.hidden = YES;
                        //清空搜索状态
                        self.isSearchStatu = NO;
                        [self.searchLists removeAllObjects];
                        [self.tableView reloadData];
                        
                        contactsDetailViewController.contactMan = model.name;
                        contactsDetailViewController.phoneNumbers = model.phoneNumber;
                        contactsDetailViewController.contactHead = model.portrait;
                        [contactsDetailViewController.ivContactMan  setImage:[UIImage imageNamed:model.portrait]];
                        [self.navigationController pushViewController:contactsDetailViewController animated:YES];
                    }
                }
            }else if ([contacts isKindOfClass:[NSDictionary class]]){
                NSDictionary *dicCallRecord = (NSDictionary *)contacts;
                
                //电话记录，拨打电话
                if (!self.callActionView){
                    self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue)];
                    
//                    [self.view addSubview:self.callActionView];
                }
                
                __weak typeof(self) weakSelf = self;
                
                self.callActionView.cancelBlock = ^(){
                    [weakSelf.callActionView hideActionView];
                };
                
                self.callActionView.actionBlock = ^(NSInteger callType){
                    [weakSelf.callActionView hideActionView];
                    if (callType==1) {
                        //网络电话
                        //电话记录，拨打电话
                        if (dicCallRecord) {
                            if ([dicCallRecord[@"calltype"] isEqualToString:@"来电"]) {
                                [weakSelf callNumber:[dicCallRecord objectForKey:@"hostnumber"]];
                            } else if ([dicCallRecord[@"calltype"] isEqualToString:@"去电"]) {
                                [weakSelf callNumber:[dicCallRecord objectForKey:@"destnumber"]];
                            } else {
                                //                HUDNormal(@"无法识别的电话方式")
                                NSLog(@"无法识别的电话方式");
                            }
                            NSLog(@"%@", dicCallRecord[@"calltype"]);
                        }
                    }else if (callType==2){
                        //手环电话
                        if ([BlueToothDataManager shareManager].isRegisted) {
                            //电话记录，拨打电话
//                            NSDictionary *dicCallRecord = [weakSelf.arrPhoneRecord objectAtIndex:indexPath.row];
                            if (dicCallRecord) {
                                if ([dicCallRecord[@"calltype"] isEqualToString:@"来电"]) {
                                    [weakSelf callUnitysNumber:[dicCallRecord objectForKey:@"hostnumber"]];
                                } else if ([dicCallRecord[@"calltype"] isEqualToString:@"去电"]) {
                                    [weakSelf callUnitysNumber:[dicCallRecord objectForKey:@"destnumber"]];
                                } else {
                                    //                HUDNormal(@"无法识别的电话方式")
                                    NSLog(@"无法识别的电话方式");
                                }
                                NSLog(@"%@", dicCallRecord[@"calltype"]);
                            }
                        } else {
                            HUDNormal(INTERNATIONALSTRING(@"手环内sim卡未注册或已掉线"))
                        }
                    }
                };
                [self.callActionView showActionView];
            }
        }else{
            //电话记录，拨打电话
            if (!self.callActionView){
                self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue)];
            }
            __weak typeof(self) weakSelf = self;
            
            self.callActionView.cancelBlock = ^(){
                [weakSelf.callActionView hideActionView];
            };
            
            self.callActionView.actionBlock = ^(NSInteger callType){
                [weakSelf.callActionView hideActionView];
                if (callType==1) {
                    //网络电话
                    //电话记录，拨打电话
//                    NSDictionary *dicCallRecord = [weakSelf.arrPhoneRecord objectAtIndex:indexPath.row];
                    NSArray *records = [weakSelf.arrPhoneRecord objectAtIndex:indexPath.row];
                    NSDictionary *dicCallRecord;
                    if (records.count) {
                        dicCallRecord = records[0];
                    }
                    if (dicCallRecord) {
                        if ([dicCallRecord[@"calltype"] isEqualToString:@"来电"]) {
                            [weakSelf callNumber:[dicCallRecord objectForKey:@"hostnumber"]];
                        } else if ([dicCallRecord[@"calltype"] isEqualToString:@"去电"]) {
                            [weakSelf callNumber:[dicCallRecord objectForKey:@"destnumber"]];
                        } else {
                            //                HUDNormal(@"无法识别的电话方式")
                            NSLog(@"无法识别的电话方式");
                        }
                        NSLog(@"%@", dicCallRecord[@"calltype"]);
                    }
                }else if (callType==2){
                    //手环电话
                    if ([BlueToothDataManager shareManager].isRegisted) {
                        //电话记录，拨打电话
//                        NSDictionary *dicCallRecord = [weakSelf.arrPhoneRecord objectAtIndex:indexPath.row];
                        NSArray *records = [weakSelf.arrPhoneRecord objectAtIndex:indexPath.row];
                        NSDictionary *dicCallRecord;
                        if (records.count) {
                            dicCallRecord = records[0];
                        }
                        if (dicCallRecord) {
                            if ([dicCallRecord[@"calltype"] isEqualToString:@"来电"]) {
                                [weakSelf callUnitysNumber:[dicCallRecord objectForKey:@"hostnumber"]];
                            } else if ([dicCallRecord[@"calltype"] isEqualToString:@"去电"]) {
                                [weakSelf callUnitysNumber:[dicCallRecord objectForKey:@"destnumber"]];
                            } else {
                                //                HUDNormal(@"无法识别的电话方式")
                                NSLog(@"无法识别的电话方式");
                            }
                            NSLog(@"%@", dicCallRecord[@"calltype"]);
                        }
                    } else {
                        HUDNormal(INTERNATIONALSTRING(@"手环内sim卡未注册或已掉线"))
                    }
                }
            };

            [self.callActionView showActionView];
        }
    } else {
        //消息记录，显示消息
        NSDictionary *dicMessageRecord = [_arrMessageRecord objectAtIndex:indexPath.row];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
        if (storyboard) {
//            self.phoneNumber= self.phonePadView.lblPhoneNumber.text;
            MJViewController *MJViewController = [storyboard instantiateViewControllerWithIdentifier:@"MJViewController"];
            if (MJViewController) {
                if ([dicMessageRecord[@"To"] isEqualToString:self.userInfo[@"Tel"]]) {
                    MJViewController.title = [self checkLinkNameWithPhoneStrMergeGroupName:[dicMessageRecord objectForKey:@"Fm"]];
                    MJViewController.toTelephone = [dicMessageRecord objectForKey:@"Fm"];
                } else {
                    MJViewController.title = [self checkLinkNameWithPhoneStrMergeGroupName:[dicMessageRecord objectForKey:@"To"]];
//                    MJViewController.title = [self checkLinkNameWithPhoneStr:[dicMessageRecord objectForKey:@"To"]];
                    MJViewController.toTelephone = [dicMessageRecord objectForKey:@"To"];
                }
                MJViewController.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:MJViewController animated:YES];
            }
        }
    }
}

//允许左滑删除
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.phoneOperation == 1) {
        return YES;
    }else if(!self.isSearchStatu && !self.lblPhoneNumber.text){
        return YES;
    }else{
        return NO;
    }
}

//左滑删除
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.phoneOperation == 1) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSDictionary *dicMessageRecord = [_arrMessageRecord objectAtIndex:indexPath.row];
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:_arrMessageRecord];
            [tempArray removeObjectAtIndex:indexPath.row];
            _arrMessageRecord = [tempArray copy];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            //从服务器删除数据
            if ([dicMessageRecord[@"To"] isEqualToString:self.userInfo[@"Tel"]]) {
                [self deleteMessageWithPhoneNumber:dicMessageRecord[@"Fm"]];
            }else{
                [self deleteMessageWithPhoneNumber:dicMessageRecord[@"To"]];
            }
        }
    }else if(!self.isSearchStatu && !self.lblPhoneNumber.text){
        //删除本地数据库数据
        [self deleteDatabaseWithIndex:indexPath tableView:tableView];
    }
}

- (void)deleteDatabaseWithIndex:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSArray *records = [self.arrPhoneRecord objectAtIndex:indexPath.row];
    NSDictionary *dicPhoneRecord;
    if (records.count) {
        dicPhoneRecord = records[0];
    }else{
        return;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
//    path = [path stringByAppendingPathComponent:@"callrecord.db"];
    path = [path stringByAppendingPathComponent:@"callrecord2.db"];
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    if (![db open]) {
        [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"删除通话记录失败") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil] show];
    }else{
        BOOL isDeleteSuccess =[db executeUpdate:@"DELETE FROM CallRecord WHERE calltime = ?",[dicPhoneRecord objectForKey:@"calltime"]];
        if (isDeleteSuccess) {
            [self.arrPhoneRecord removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [db close];
    }

}

- (void)deleteMessageWithPhoneNumber:(NSString *)phoneNumber
{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: phoneNumber ,@"Tel",nil];
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiDeletesByTel params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"删除单条短信成功");
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"删除单条短信失败");
        }
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"删除单条短信异常：%@",[error description]);
    } headers:self.headers];
    
//    [SSNetworkRequest getRequest:apiDeletesByTel params:nil success:^(id responseObj) {
//        NSLog(@"有数据：%@",responseObj);
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }else{
//            //数据请求失败
//        }
//        
//    } failure:^(id dataObj, NSError *error) {
//        NSLog(@"有异常：%@",[error description]);
//    } headers:self.headers];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"错误提示"]) {
        [self OnCallEnded];
    }
}

//滑动时隐藏键盘
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.isSearchStatu && self.lblPhoneNumber.text) {
        [self switchNumberPad:YES];
        [self.callView.btnSwitchNumberPad setImage:[UIImage imageNamed:@"tel_numberpad_pulloff"] forState:UIControlStateNormal];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"sendMessageSuccess" object:@"sendMessageSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addressBookChanged" object:@"addressBook"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CallingAction" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MakeCallAction" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MakeUnitysCallAction" object:nil];
}
@end
