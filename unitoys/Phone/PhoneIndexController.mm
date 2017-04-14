//
//  PhoneIndexController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "PhoneIndexController.h"
#import "HLTitlesView.h"
#import "global.h"
#import "PhoneRecordController.h"
#import "MessageRecordController.h"
#import "NewMessageViewController.h"

@interface PhoneIndexController ()

@property (nonatomic, weak) HLTitlesView *titleView;

@end

@implementation PhoneIndexController

- (instancetype)init
{
    if (self = [super init]) {
        [self setupViewChildControllers];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self setupViewChildControllers];
    }
    return self;
}

//为了提前注册,需要在创建时初始化子控制器
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setupViewChildControllers];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpTitlesView];
}

- (BOOL)initEngine
{
    if (self.viewControllers.count) {
        if ([self.viewControllers.firstObject isKindOfClass:[PhoneRecordController class]]) {
            PhoneRecordController *vc1 = self.viewControllers.firstObject;
            return [vc1 initEngine];
        }
    }
    return NO;
}
- (void)unregister
{
    if (self.viewControllers.count) {
        if ([self.viewControllers.firstObject isKindOfClass:[PhoneRecordController class]]) {
            PhoneRecordController *vc1 = self.viewControllers.firstObject;
            [vc1 unregister];
        }
    }
}
//- (void)loadMessage
//{
//    
//}

//设置导航栏
- (void)setUpTitlesView
{
    kWeakSelf
    HLTitlesView *titlesView = [HLTitlesView titlesViewWithTitles:@[@"通话历史", @"短信记录"]  Margin:15];
    titlesView.titlesButtonAction = ^(UIButton *button){
        NSLog(@"%ld", button.tag);
//        if (button.tag == 0) {
//            self.navigationItem.rightBarButtonItem = nil;
//        }else{
//            [self initRightButton];
//        }
        NSArray *startController = @[weakSelf.viewControllers[button.tag]];
        [weakSelf.pageViewController setViewControllers:startController
                                              direction: UIPageViewControllerNavigationDirectionReverse
                                               animated:NO
                                             completion:nil];
    };
    self.titleView = titlesView;
    self.navigationItem.titleView = titlesView;
//    [self.navigationController.navigationBar addSubview:titlesView];
}

- (void)initRightButton
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit_info_nor"] style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonAction)];
}

- (void)rightButtonAction
{
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    NewMessageViewController *newMessageViewController = [mainStory instantiateViewControllerWithIdentifier:@"newMessageViewController"];
    if (newMessageViewController) {
        //writeMessageViewController.destNumber = [dicPackage objectForKey:@"PackageId"];
        [self.navigationController pushViewController:newMessageViewController animated:YES];
    }
}

//#pragma mark
//#pragma mark Override
- (void)setupViewChildControllers
{
    kWeakSelf
    PhoneRecordController *vc1  = [[PhoneRecordController alloc] init];
    vc1.isHideTitleViewBlock = ^(BOOL isHidden) {
        weakSelf.titleView.hidden = isHidden;
    };
    MessageRecordController *vc2  = [[MessageRecordController alloc] init];
    vc1.nav = self.navigationController;
    vc2.nav = self.navigationController;
    self.viewControllers = @[vc1, vc2];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)isShowLeftButton
{
    return NO;
}

@end
