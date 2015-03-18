//
//  ViewController.m
//  macdemo
//
//  Created by YANG HONGBO on 2015-3-19.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface ViewController () <CBPeripheralManagerDelegate>
{
    CLLocationManager *_manager;
    CBPeripheralManager *_peripheralManger;
}
@end

#define SERVICE_UUID @"E5DA0446-9FAB-4ABA-AA6D-23CDFC0AAFDB"
#define CHAR_UUID @"5831890D-5106-4031-AEF0-725DDB2F08A7"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    CBMutableCharacteristic *ch = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CHAR_UUID]
                                                                     properties:CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite|CBCharacteristicPropertyNotify
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
    CBMutableService *s = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:SERVICE_UUID]
                                                         primary:YES];
    s.characteristics = @[ch];
    _peripheralManger = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    [_peripheralManger addService:s];
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (CBPeripheralManagerStatePoweredOn == peripheral.state) {
        
    }
}


- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"peripheralManagerDidStartAdvertising");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (CBPeripheralManagerStatePoweredOn == peripheral.state) {
        id array = @[[CBUUID UUIDWithString:SERVICE_UUID]];
        [peripheral startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:array,
                                       CBAdvertisementDataLocalNameKey: @"MacBle"}];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"didReceiveReadRequest from:%@", request.characteristic.UUID);
    if ([request.characteristic.UUID isEqualTo:[CBUUID UUIDWithString:CHAR_UUID]]) {
        const char a[] = {1, 2, 3, 4};
        NSData *value = [NSData dataWithBytes:a length:sizeof(a)];
        request.value = value;
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    for (CBATTRequest *request in requests) {
        NSLog(@"didReceiveWriteRequest from:%@", request.characteristic.UUID);
        if ([request.characteristic.UUID isEqualTo:[CBUUID UUIDWithString:CHAR_UUID]]) {
            const char a[] = {1, 2, 3, 4};
            NSData *value = [NSData dataWithBytes:a length:sizeof(a)];
            request.value = value;
            
            [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        }
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"didSubscribeToCharacteristic:%@", characteristic.UUID);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"didUnsubscribeFromCharacteristic:%@", characteristic.UUID);
}
@end
