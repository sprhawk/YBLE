//
//  YBlePeripheralInternal.h
//  yble
//
//  Created by YANG HONGBO on 2015-3-18.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import "YBlePeripheral.h"

typedef NS_ENUM(NSUInteger, YBlePeripheralInteralState) {
    YBlePeripheralInteralStateDisconnected,
    YBlePeripheralInteralStateConnected,
    YBlePeripheralInteralStateFailToConnect,
};

@interface YBlePeripheral (Internal)

- (void)centralUpdatePeripheralState:(YBlePeripheralInteralState)state error:(NSError *)error;
- (void)centralUpdatePeripheralAdvertisementData:(NSDictionary *)advertisementData rssi:(NSNumber *)rssi lastFound:(NSDate *)date;

@end