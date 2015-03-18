//
//  ConnectViewController.h
//  yble
//
//  Created by YANG HONGBO on 2015-3-18.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "yble.h"

@interface ConnectViewController : UITableViewController
@property (nonatomic, strong, readwrite) YBlePeripheral *peripheral;
@end
