//
//  yble_internal.h
//  yble
//
//  Created by YANG HONGBO on 2015-3-18.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import "yble.h"

@class YBlePeripheral;

@interface YBleCentral (Internal)
- (void)dispatchCallback:(void (^)(void))block;
// options is same as CBCentralManager's Peripheral Connection Options
- (void)connectPeripheral:(YBlePeripheral *)peripheral options:(NSDictionary *)options;
- (void)connectPeripheral:(YBlePeripheral *)peripheral;
- (void)disconnectPeripheral:(YBlePeripheral *)peripheral;
@end