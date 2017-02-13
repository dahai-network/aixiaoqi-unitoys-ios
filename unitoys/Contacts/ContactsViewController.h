//
//  ContactsViewController.h
//  unitoys
//
//  Created by sumars on 16/9/23.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"
#import "ContactsDetailViewController.h"


@interface ContactsViewController : BaseViewController<PhoneNumberSelectDelegate>

@property (strong,nonatomic) id delegate;
@property (readwrite) BOOL bOnlySelectNumber;

@property (readwrite) BOOL bFinishedEdit;

@end
