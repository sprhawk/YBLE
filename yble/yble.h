//
//    Copyright (c) 2015 YANG HONGBO
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.

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
