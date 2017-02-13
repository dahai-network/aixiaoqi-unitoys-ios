//
//  ProfileViewController.h
//  unitoys
//
//  Created by sumars on 16/11/3.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"

#import "VPImageCropperViewController.h"



@interface ProfileViewController : BaseTableController<UIPickerViewDataSource,UIPickerViewDelegate,VPImageCropperDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *ivUserHead;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UILabel *lblSex;
@property (weak, nonatomic) IBOutlet UILabel *lblAge;
@property (weak, nonatomic) IBOutlet UILabel *lblHeight;
@property (weak, nonatomic) IBOutlet UILabel *lblWeight;
@property (weak, nonatomic) IBOutlet UILabel *lblTarget;
@property (weak, nonatomic) IBOutlet UILabel *lblBmi;

@property (weak, nonatomic) UIView *valueView;

@property (readwrite) UIPickerView *pickerView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (strong,nonatomic) NSMutableDictionary *dicInfo;

@property (strong,nonatomic) NSArray *arrSex;

@property (strong,nonatomic) NSArray *arrAgeYear;
@property (nonatomic, strong) NSArray *arrAgeMonth;

@property (strong,nonatomic) NSArray *arrHeight;

@property (strong,nonatomic) NSArray *arrWeight;

@property (strong,nonatomic) NSArray *arrTarget;

@property (readwrite) NSArray *arrSource;

@property (readwrite) int pickerType;

@property (nonatomic, assign) int yearStr;//当前年
@property (nonatomic, assign) int monthStr;// 当前月

@end
