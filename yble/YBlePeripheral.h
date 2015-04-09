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

typedef NS_ENUM(NSUInteger, YBlePeripheralState) {
    YBlePeripheralStateIdle = 0,
    YBlePeripheralStateConnecting,
    YBlePeripheralStateConnected,
    YBlePeripheralStateDisconnecting,
};

@class YBleCentral;
@class YBleService, YBleCharacteristic;

typedef void(^PeripheralNameUpdatedBlock)(NSString *name);
typedef void(^PeripheralStateUpdatedBlock)(YBlePeripheralState state, NSError *error);

typedef void(^ServicesDiscoveredBlock)(YBleService *service, NSError *error);
typedef void(^ValueUpdatedBlock)(NSData *data, NSError *error);
typedef void(^ValueWrittenBlock)(NSData *data, NSError *error);
typedef void(^NotificationStateBlock)(BOOL notifying, NSError *error);
typedef void(^RssiUpdatedBlock)(NSNumber *rssi, NSError *error);

@interface YBlePeripheral : NSObject
@property (weak, readonly) YBleCentral *central;
@property (strong, readonly) CBPeripheral *cbperipheral;
@property (strong, readonly) NSUUID *uuid;
@property (strong, readonly) NSString *name;
@property (assign, readonly) YBlePeripheralState state;
@property (strong, readonly) NSDictionary *advertisementData;
@property (strong, readonly) NSNumber *rssi;
@property (strong, readonly) NSDate *lastFound;

@property (copy, readwrite) PeripheralNameUpdatedBlock nameUpdateBlock;
@property (copy, readwrite) PeripheralStateUpdatedBlock stateUpdateBlock;

- (instancetype)initWithCBPeripheral:(CBPeripheral *)peripheral central:(YBleCentral *)central;
// options is same as CBCentralManager's Peripheral Connection Options
- (void)connectWithOptions:(NSDictionary *)options;
- (void)connect;
- (void)disconnect;
- (void)discoverServices:(NSArray *)services discovered:(ServicesDiscoveredBlock)block;
- (void)readRssiCallback:(RssiUpdatedBlock)block;

/*****
 * there are three groups of get value updated from characteristic. do not mix use them for single characteristic.
 */
- (void)setValueUpdatedBlock:(ValueUpdatedBlock)block forCharacteristic:(YBleCharacteristic *)characteristic;
- (void)readCharacteristic:(YBleCharacteristic *)characteristic;
- (void)setCharacteristic:(YBleCharacteristic *)characteristic notifying:(BOOL)notifying stateCallback:(NotificationStateBlock)stateBlock;

- (void)readCharacteristic:(YBleCharacteristic *)characteristic callback:(ValueUpdatedBlock)block;

- (void)setCharacteristic:(YBleCharacteristic *)characteristic notifying:(BOOL)notifying stateCallback:(NotificationStateBlock)stateBlock valueCallback:(ValueUpdatedBlock)valueBlock;

/*
 *****/

- (void)writeCharacteristic:(YBleCharacteristic *)characteristic value:(NSData *)data callback:(ValueWrittenBlock)callback;

@end

@interface CBPeripheral (universeralIdentifier)
- (NSUUID *)uuid;
@end

@interface YBleService : NSObject
@property (strong, readonly) CBUUID *uuid;
@property (strong, readonly) NSDictionary *characteristics;

- (instancetype)initWithUUID:(CBUUID *)uuid;
- (void)addCharacteristic:(YBleCharacteristic*)characteristic;
@end

@interface YBleCharacteristic : NSObject
@property (strong, readonly) CBUUID *uuid;

@property (weak, readonly) YBleService *service;
@property (assign, readonly) BOOL isNotifying;
@property (assign, readonly) CBCharacteristicProperties properties;

- (instancetype)initWithUUID:(CBUUID *)uuid;
- (void)readValue:(ValueUpdatedBlock)block;
- (void)writeValue:(NSData *)value callback:(ValueWrittenBlock)block;
@end