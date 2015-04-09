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

#import "YBlePeripheral.h"
#import "yble_internal.h"
#import "YBlePeripheralInternal.h"
#import "NSMutableArray+FifoQueue.h"
#import "NSMutableDictionary+FifoQueue.h"

@interface YBleService ()
@property (strong, readwrite) CBUUID *uuid;
@property (strong, readwrite) NSMutableDictionary *inCharacteristics;
@property (strong, readwrite) CBService *cbservice;
@property (weak, readwrite) YBlePeripheral *peripheral;
@end

@interface YBleCharacteristic ()
@property (strong, readwrite) CBUUID *uuid;
@property (weak, readwrite) YBleService *service;
@property (strong, readwrite) CBCharacteristic *cbcharacteristic;
@property (assign, readwrite) BOOL isNotifying;
@property (weak, readwrite) YBlePeripheral *peripheral;
@end

@interface YBlePeripheral () <CBPeripheralDelegate>

@property (weak, readwrite) YBleCentral *central;
@property (strong, readwrite) CBPeripheral *cbperipheral;
@property (strong, readwrite) NSUUID *uuid;
@property (strong, readwrite) NSDictionary *advertisementData;
@property (strong, readwrite) NSNumber *rssi;
@property (strong, readwrite) NSDate *lastFound;
@property (assign, readwrite) YBlePeripheralState state;
@property (strong, readwrite) NSMutableDictionary *services;

@property (strong, readwrite) NSMutableDictionary *valueUpdatedBlocks;
@property (strong, readwrite) NSMutableDictionary *readingBlocks;
@property (strong, readwrite) NSMutableDictionary *notificationValueBlocks;

@property (strong, readwrite) NSMutableArray *writingBlocks;
@property (strong, readwrite) NSMutableDictionary *notificationStateBlocks;

@property (copy, readwrite) RssiUpdatedBlock rssiUpdatedBlock;
@property (copy, readwrite) ServicesDiscoveredBlock servicesDiscoveredBlock;

- (void)updateState:(YBlePeripheralState)state withError:(NSError *)error;
@end

@implementation YBlePeripheral
@synthesize state = _state;

- (instancetype)initWithCBPeripheral:(CBPeripheral *)peripheral central:(YBleCentral *)central
{
    self = [super init];
    
    if (self) {
        self.central = central;
        self.cbperipheral = peripheral;
        peripheral.delegate = self;
        self.uuid = peripheral.uuid;
        self.state = YBlePeripheralStateIdle;
        
        self.valueUpdatedBlocks = [NSMutableDictionary dictionary];
        self.writingBlocks = [NSMutableArray array];
        self.notificationValueBlocks = [NSMutableDictionary dictionary];
        self.notificationStateBlocks = [NSMutableDictionary dictionary];
        self.readingBlocks = [NSMutableDictionary dictionary];
        
        self.services = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)connectWithOptions:(NSDictionary *)options
{
    if (YBlePeripheralStateIdle == self.state) {
        self.state = YBlePeripheralStateConnecting;
        [self.central connectPeripheral:self options:options];
    }
}

- (void)connect
{
    [self connectWithOptions:nil];
}

- (void)disconnect
{
    if (YBlePeripheralStateIdle != self.state) {
        self.state = YBlePeripheralStateDisconnecting;
        [self.central disconnectPeripheral:self];
    }
}

- (void)discoverServices:(NSArray *)services discovered:(ServicesDiscoveredBlock)block
{
    self.servicesDiscoveredBlock = block;
    NSMutableArray *discoveringServices = nil;
    if (services) {
        discoveringServices = [NSMutableArray arrayWithCapacity:services.count];
        for (YBleService *service in services) {
            [discoveringServices addObject:service.uuid];
        }
    }
    [self.cbperipheral discoverServices:discoveringServices];
}

- (void)setValueUpdatedBlock:(ValueUpdatedBlock)block forCharacteristic:(YBleCharacteristic *)characteristic
{
    self.valueUpdatedBlocks[characteristic.uuid] = [block copy];
}

- (void)readCharacteristic:(YBleCharacteristic *)characteristic
{
    CBCharacteristic *ch = characteristic.cbcharacteristic;
    if (nil == ch) {
        @throw NSInvalidArgumentException;
    }
    [self.cbperipheral readValueForCharacteristic:ch];
}

- (void)readCharacteristic:(YBleCharacteristic *)characteristic callback:(ValueUpdatedBlock)block
{
    if (block) {
        CBCharacteristic *ch = characteristic.cbcharacteristic;
        if (nil == ch) {
            @throw NSInvalidArgumentException;
        }
        [self.readingBlocks pushObject:[block copy] inQueue:characteristic.uuid];
        [self.cbperipheral readValueForCharacteristic:ch];
    }
}

- (void)writeCharacteristic:(YBleCharacteristic *)characteristic value:(NSData *)data callback:(ValueWrittenBlock)callback
{
    CBCharacteristic *ch = characteristic.cbcharacteristic;
    if (nil == ch) {
        @throw NSInvalidArgumentException;
    }
    CBCharacteristicWriteType type = CBCharacteristicWriteWithoutResponse;
    if (callback) {
        type = CBCharacteristicWriteWithResponse;
        [self.writingBlocks push:[callback copy]];
    }
    [self.cbperipheral writeValue:data forCharacteristic:ch type:type];
}

- (void)setCharacteristic:(YBleCharacteristic *)characteristic notifying:(BOOL)notifying stateCallback:(NotificationStateBlock)stateBlock
{
    if (notifying == characteristic.isNotifying) {
        if (stateBlock) {
            stateBlock(notifying, nil);
        }
    }
    else {
        if (stateBlock) {
            self.notificationStateBlocks[characteristic.uuid] = [stateBlock copy];
        }
        [self.cbperipheral setNotifyValue:notifying forCharacteristic:characteristic.cbcharacteristic];
    }
}

- (void)setCharacteristic:(YBleCharacteristic *)characteristic notifying:(BOOL)notifying stateCallback:(NotificationStateBlock)stateBlock valueCallback:(ValueUpdatedBlock)valueBlock
{
    if (notifying && valueBlock) {
        [self.notificationValueBlocks pushObject:[valueBlock copy] inQueue:characteristic.uuid];
    }
    
    [self setCharacteristic:characteristic notifying:notifying stateCallback:stateBlock];
}

- (void)readRssiCallback:(RssiUpdatedBlock)block
{
    if (block) {
        self.rssiUpdatedBlock = block;
        [self.cbperipheral readRSSI];
    }
}

#pragma mark - Properties

- (NSString *)name
{
    return self.cbperipheral.name;
}

- (void)setState:(YBlePeripheralState)state
{
    [self updateState:state withError:nil];
}

- (YBlePeripheralState)state
{
    @synchronized(self) {
        return _state;
    }
}
- (void)updateState:(YBlePeripheralState)state withError:(NSError *)error
{
    @synchronized(self) {
        _state = state;
        if (self.stateUpdateBlock) {
            [self.central dispatchCallback:^{
                self.stateUpdateBlock(state, error);
            }];
        }
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@(%@)", self.name, self.uuid.UUIDString];
}

#pragma mark - Helper
- (CBService *)serviceForUUID:(CBUUID *)uuid
{
    for (CBService *s in self.cbperipheral.services) {
        if ([s.UUID isEqual:uuid]) {
            return s;
        }
    }
    return nil;
}

- (CBCharacteristic *)characteristicForUUID:(CBUUID *)uuid inService:(CBService *)service
{
    for (CBCharacteristic *c in service.characteristics) {
        if ([c.UUID isEqual:uuid]) {
            return c;
        }
    }
    return nil;
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (nil == error) {
        YBleService *s = self.services[service.UUID];
        if (nil == s) {
            s = [[YBleService alloc] initWithUUID:service.UUID];
            self.services[service.UUID] = s;
            s.cbservice = service;
        }
        for (CBCharacteristic *c in service.characteristics) {
            YBleCharacteristic *ch = s.characteristics[c];
            if (nil == ch) {
                ch = [[YBleCharacteristic alloc] initWithUUID:c.UUID];
                [s addCharacteristic:ch];
            }
            ch.cbcharacteristic = c;
            ch.peripheral = self;
        }
        if (self.servicesDiscoveredBlock) {
            [self.central dispatchCallback:^{
                self.servicesDiscoveredBlock(s, nil);
            }];
        }
    }
    else {
        if (self.servicesDiscoveredBlock) {
            [self.central dispatchCallback:^{
                self.servicesDiscoveredBlock(nil, error);
            }];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (nil == error) {
        for (CBService *service in peripheral.services) {
            YBleService *s = self.services[service.UUID];
            if (nil == s.cbservice) {
                s.cbservice = service;
            }
            s.peripheral = self;
            NSMutableArray *array = nil;
            if (s.characteristics.count) {
                array = [NSMutableArray array];
                for (YBleCharacteristic *c in s.characteristics.allValues) {
                    if (nil == c.cbcharacteristic) {
                        [array addObject:c.uuid];
                    }
                }
            }
            [peripheral discoverCharacteristics:array forService:service];
        }
        
    }
    else {
        if (self.servicesDiscoveredBlock) {
            [self.central dispatchCallback:^{
                self.servicesDiscoveredBlock(nil, error);
            }];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices
{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    if (self.rssiUpdatedBlock) {
        [self.central dispatchCallback:^{
            self.rssiUpdatedBlock(RSSI, error);
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NotificationStateBlock block = self.notificationStateBlocks[characteristic.UUID];
    if (block) {
        [self.central dispatchCallback:^{
            block(characteristic.isNotifying, error);
        }];
        [self.notificationStateBlocks removeObjectForKey:characteristic.UUID];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // hope users will not mix use these three methods
    ValueUpdatedBlock block = self.valueUpdatedBlocks[characteristic.UUID];
    if (block) {
        [self.central dispatchCallback:^{
            block(characteristic.value, error);
        }];
    }
    block = [self.readingBlocks popObjectInQueue:characteristic.UUID];
    if (block) {
        [self.central dispatchCallback:^{
            block(characteristic.value, error);
        }];
    }
    block = self.notificationValueBlocks[characteristic.UUID];
    if (block) {
        [self.central dispatchCallback:^{
            block(characteristic.value, error);
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    ValueWrittenBlock block = [self.writingBlocks pop];
    [self.central dispatchCallback:^{
        block(characteristic.value, error);
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    if (self.nameUpdateBlock) {
        [self.central dispatchCallback:^{
            self.nameUpdateBlock(peripheral.name);
        }];
    }
}


@end

@implementation YBlePeripheral (Internal)

- (void)centralUpdatePeripheralState:(YBlePeripheralInteralState)state error:(NSError *)error
{
    switch (state) {
        case YBlePeripheralInteralStateConnected:
            self.state = YBlePeripheralStateConnected;
            break;
        case YBlePeripheralInteralStateDisconnected:
            self.state = YBlePeripheralStateIdle;
            break;
        case YBlePeripheralInteralStateFailToConnect:
            self.state = YBlePeripheralStateIdle;
            break;
        default:
            break;
    }
}

- (void)centralUpdatePeripheralAdvertisementData:(NSDictionary *)advertisementData rssi:(NSNumber *)rssi lastFound:(NSDate *)date
{
    self.advertisementData = advertisementData;
    self.rssi = rssi;
    self.lastFound = date;
}

@end

@implementation CBPeripheral (universeralIdentifier)

- (NSUUID *)uuid
{
    if ([self respondsToSelector:@selector(identifier)]) {
        return self.identifier;
    }
    else {
//        NSString * string = CFBridgingRelease(CFUUIDCreateString(NULL, self.UUID));
//        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:string];
        CFUUIDBytes bytes = CFUUIDGetUUIDBytes(self.UUID);
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:(const unsigned char *)&bytes];
        return uuid;
    }
}

@end

@implementation YBleService

- (instancetype)initWithUUID:(CBUUID *)uuid
{
    self = [super init];
    if (self) {
        self.uuid = uuid;
        self.inCharacteristics = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSDictionary *)characteristics
{
    return [self.inCharacteristics copy];
}

- (void)addCharacteristic:(YBleCharacteristic *)characteristic
{
    characteristic.service = self;
    self.inCharacteristics[characteristic.uuid] = characteristic;
}

@end

@implementation YBleCharacteristic

- (instancetype)initWithUUID:(CBUUID *)uuid
{
    self = [super init];
    if (self) {
        self.uuid = uuid;
    }
    return self;
}

- (CBCharacteristicProperties)properties
{
    return self.cbcharacteristic.properties;
}

- (void)readValue:(ValueUpdatedBlock)block
{
    [self.peripheral readCharacteristic:self callback:block];
}

- (void)writeValue:(NSData *)value callback:(ValueWrittenBlock)block
{
    [self.peripheral writeCharacteristic:self value:value callback:block];
}
@end