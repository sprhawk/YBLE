//
//  yble.h
//  yble
//
//  Created by YANG HONGBO on 2015-3-18.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "YBlePeripheral.h"

#define YBLELOG(s, ...) NSLog(@"YBle(%s:%d): " s, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

typedef NS_ENUM(NSUInteger, YBleState) {
    YBleStateUnknown,
    YBleStatePoweredOff,
    YBleStatePoweredOn,
    YBleStateUnauthorized,
    YBleStateUnsupported,
    YBleStateResetting,
};

typedef void(^CentralStateUpdateBlock)(YBleState state);
typedef void(^ScanResultCallback)(YBlePeripheral *peripheral);

@interface YBleCentral : NSObject
@property (assign, readonly) YBleState state;
@property (assign, readonly) BOOL isAvailable;
@property (assign, readonly) BOOL isScanning;
@property (strong, readonly) NSDictionary *scanOptions;
@property (copy) CentralStateUpdateBlock stateUpdateBlock;

// central manager uses its own queue, and user should specify a callback queue.
// if callback queue is nil, central will dispatch callback to its own queue.
- (instancetype)initWithStateCallback:(CentralStateUpdateBlock)block restoreIdentifier:(NSString *)identifier;
- (instancetype)initInMainQueueWithStateCallback:(CentralStateUpdateBlock)block restoreIdentifier:(NSString *)identifier;
- (instancetype)initInCallbackQueue:(dispatch_queue_t)queue withStateCallback:(CentralStateUpdateBlock)block restoreIdentifier:(NSString *)identifier;

- (void)scanForServices:(NSArray *)services options:(NSDictionary *)options callback:(ScanResultCallback)block;
- (void)stopScan;

@end
