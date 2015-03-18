//
//  CharacteristicViewController.h
//  yble
//
//  Created by YANG HONGBO on 2015-3-19.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "yble.h"

@interface CharacteristicViewController : UIViewController
@property (nonatomic, strong, readwrite) YBleCharacteristic *characteristic;
@end
