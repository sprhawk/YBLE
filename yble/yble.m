//
//  yble.m
//  yble
//
//  Created by YANG HONGBO on 2015-3-18.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import "yble.h"
#import "yble_internal.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import "YBlePeripheral.h"
#import "YBlePeripheralInternal.h"

@interface YBleCentral () <CBCentralManagerDelegate>

@property (assign, readwrite) YBleState state;

@property (nonatomic, strong, readwrite) CBCentralManager * centralManager;
@property (nonatomic, strong, readwrite) NSMutableDictionary * managedPeripherals;

@property (nonatomic, strong, readwrite) dispatch_queue_t centralQueue;
@property (nonatomic, strong, readwrite) dispatch_queue_t callbackQueue;

@property (copy) ScanResultCallback scanResultCallback;
@property (assign, readwrite) BOOL isScanning;
@property (strong, readwrite) NSDictionary *scanOptions;

@end

@implementation YBleCentral
@synthesize state = _state;

// disable init
- (instancetype)init
{
    self = nil;
    return self;
}

- (instancetype)initWithStateCallback:(CentralStateUpdateBlock)block restoreIdentifier:(NSString *)identifier
{
    self = [self initInCallbackQueue:nil withStateCallback:block restoreIdentifier:identifier];
    return self;
}

- (instancetype)initInMainQueueWithStateCallback:(CentralStateUpdateBlock)block restoreIdentifier:(NSString *)identifier
{
    self = [self initInCallbackQueue:dispatch_get_main_queue()
                   withStateCallback:block
                   restoreIdentifier:identifier];
    return self;
}

- (instancetype)initInCallbackQueue:(dispatch_queue_t)queue withStateCallback:(CentralStateUpdateBlock)block restoreIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        self.managedPeripherals = [NSMutableDictionary dictionary];
        self.callbackQueue = queue;
        self.centralQueue = dispatch_queue_create("yble_central_queue", NULL);
        self.stateUpdateBlock = block;
        
        if ([CBCentralManager instancesRespondToSelector:@selector(initWithDelegate:queue:options:)] ) {
            NSDictionary *options = nil;
            if (identifier) {
                options = @{CBCentralManagerOptionRestoreIdentifierKey: identifier};
            }
            self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                       queue:self.centralQueue
                                                                     options:options];
        }
        else {
            self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                       queue:self.centralQueue];
        }
    }
    return self;
}

- (void)scanForServices:(NSArray *)services options:(NSDictionary *)options callback:(ScanResultCallback)block
{
    if (YBleStatePoweredOn == self.state) {
        self.scanResultCallback = block;
        self.isScanning = YES;
        self.scanOptions = options;
        [self.centralManager scanForPeripheralsWithServices:services
                                                    options:options];
    }
    else {
        YBLELOG(@"central is not powered on");
    }
}

- (void)stopScan
{
    self.scanResultCallback = nil;
    [self.centralManager stopScan];
    self.isScanning = NO;
    self.scanOptions = nil;
}

- (void)setState:(YBleState)state
{
    @synchronized(self) {
        _state = state;
        if (self.stateUpdateBlock) {
            [self dispatchCallback:^{
                self.stateUpdateBlock(state);
            }];
        }
    }
}

- (YBleState)state
{
    @synchronized(self) {
        return _state;
    }
}

#pragma CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            self.state = YBleStatePoweredOff;
            break;
        case CBCentralManagerStatePoweredOn:
            self.state = YBleStatePoweredOn;
            break;
        case CBCentralManagerStateUnauthorized:
            self.state = YBleStateUnauthorized;
            break;
        case CBCentralManagerStateResetting:
            self.state = YBleStateResetting;
            break;
        case CBCentralManagerStateUnsupported:
            self.state = YBleStateUnsupported;
            break;
        case CBCentralManagerStateUnknown:
        default:
            self.state = YBleStateUnknown;
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    YBlePeripheral *p = self.managedPeripherals[peripheral.uuid];
    if (nil == p) {
        p = [[YBlePeripheral alloc] initWithCBPeripheral:peripheral central:self];
        self.managedPeripherals[peripheral.uuid] = p;
    }
    
    [p centralUpdatePeripheralAdvertisementData:advertisementData rssi:RSSI lastFound:[NSDate date]];
    
    if (self.scanResultCallback) {
        [self dispatchCallback:^{
            self.scanResultCallback(p);
        }];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    YBlePeripheral *p = self.managedPeripherals[peripheral.uuid];
    if (p) {
        [p centralUpdatePeripheralState:YBlePeripheralInteralStateConnected error:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    YBlePeripheral *p = self.managedPeripherals[peripheral.uuid];
    if (p) {
        [p centralUpdatePeripheralState:YBlePeripheralInteralStateDisconnected error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    YBlePeripheral *p = self.managedPeripherals[peripheral.uuid];
    if (p) {
        [p centralUpdatePeripheralState:YBlePeripheralInteralStateFailToConnect error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    
}

@end

@implementation YBleCentral (Internal)
- (void)dispatchCallback:(void (^)(void))block
{
    dispatch_queue_t queue = self.callbackQueue ? self.callbackQueue : dispatch_get_main_queue();
    dispatch_async(queue, ^{
        block();
    });
}

- (void)connectPeripheral:(YBlePeripheral *)peripheral options:(NSDictionary *)options
{
    YBlePeripheral *p = self.managedPeripherals[peripheral.uuid];
    if (p == peripheral) {
        [self.centralManager connectPeripheral:p.cbperipheral options:options];
    }
    else {
        YBLELOG(@"The peripheral to be connected should be managed by central");
        @throw NSInvalidArgumentException;
    }
}

- (void)connectPeripheral:(YBlePeripheral *)peripheral
{
    [self connectPeripheral:peripheral options:nil];
}

- (void)disconnectPeripheral:(YBlePeripheral *)peripheral
{
    YBlePeripheral *p = self.managedPeripherals[peripheral.uuid];
    if (p == peripheral) {
        [self.centralManager cancelPeripheralConnection:p.cbperipheral];
    }
    else {
        YBLELOG(@"The peripheral to be disconnected should be managed by central");
        @throw NSInvalidArgumentException;
    }
}
@end
                           
                           
