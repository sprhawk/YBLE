//
//  ConnectViewController.m
//  yble
//
//  Created by YANG HONGBO on 2015-3-18.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import "ConnectViewController.h"
#import "CharacteristicViewController.h"

@interface ConnectViewController ()

@property (nonatomic, strong, readwrite) NSMutableArray *services;

@end

@implementation ConnectViewController

- (void)awakeFromNib
{
    self.services = [NSMutableArray array];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    __weak ConnectViewController *SELF = self;
    self.peripheral.stateUpdateBlock = ^(YBlePeripheralState state, NSError *error) {
        NSLog(@"state:%d error:%@", (int)state, error);
        if (YBlePeripheralStateConnected == state) {
//            YBleService *s = [[YBleService alloc] initWithUUID:[CBUUID UUIDWithString:@"1802"]];
//            YBleCharacteristic *c = [[YBleCharacteristic alloc] initWithUUID:[CBUUID UUIDWithString:@"1821"]];
//            [s addCharacteristic:c];
            [SELF.peripheral discoverServices:nil
                                   discovered:^(YBleService *service, NSError *error) {
                                       [SELF didDiscoverService:service error:error];
                                   }];
        }
    };
    [self.peripheral connect];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (NSNotFound == [self.navigationController.viewControllers indexOfObject:self]) {
        [self.peripheral disconnect];
    }
}

- (void)didDiscoverService:(YBleService *)service error:(NSError *)error
{
    NSLog(@"didDiscoverService:%@", service.uuid.UUIDString);
    if (service) {
        [self.services addObject:service];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:self.services.count - 1] withRowAnimation:UITableViewRowAnimationAutomatic];
//        const CBUUID *type = [CBUUID UUIDWithString:@"5831890D-5106-4031-AEF0-725DDB2F08A7"];
//        for (YBleCharacteristic *c in service.characteristics.allValues) {
//            NSLog(@"    characteristic:%@", c.uuid);
//            if ([c.uuid isEqual:type]) {
//                [self.peripheral setValueUpdatedBlock:^(NSData *data, NSError *error) {
//                    NSLog(@"     characteristic:%@ value:%@", c.uuid, data);
//                } forCharacteristic:c];
//                [self.peripheral readCharacteristic:c];
//            }
//        }
    }
    else if(error) {
        NSLog(@"didDiscoverService error:%@", error);
    }
    else {
        NSLog(@"didDiscoverService error:Unknown reason");
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.services.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    YBleService *s = self.services[section];
    return s.characteristics.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    YBleService *s = self.services[section];
    return [NSString stringWithFormat:@"%@", s.uuid.UUIDString];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    YBleService *s = self.services[indexPath.section];
    YBleCharacteristic *c = s.characteristics.allValues[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", c.uuid.UUIDString];
    NSMutableArray *array = [NSMutableArray array];
    if (c.properties & CBCharacteristicPropertyRead) {
        [array addObject:@"read"];
    }
    if (c.properties & CBCharacteristicPropertyWrite) {
        [array addObject:@"write"];
    }
    if (c.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        [array addObject:@"writeW/OResp"];
    }
    if (c.properties & CBCharacteristicPropertyNotify) {
        [array addObject:@"notify"];
    }
    if (c.properties & CBCharacteristicPropertyNotifyEncryptionRequired) {
        [array addObject:@"notifyEnc"];
    }
    if (c.properties & CBCharacteristicPropertyIndicate) {
        [array addObject:@"indicate"];
    }
    if (c.properties & CBCharacteristicPropertyIndicateEncryptionRequired) {
        [array addObject:@"indicateEnc"];
    }
    if (c.properties & CBCharacteristicPropertyAuthenticatedSignedWrites) {
        [array addObject:@"authSignedWrites"];
    }
    if (c.properties & CBCharacteristicPropertyExtendedProperties) {
        [array addObject:@"extended"];
    }
    if (c.properties & CBCharacteristicPropertyBroadcast) {
        [array addObject:@"broadcast"];
    }
    cell.detailTextLabel.text = [array componentsJoinedByString:@" "];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    YBleService *s = self.services[indexPath.section];
    YBleCharacteristic *c = s.characteristics.allValues[indexPath.row];
    [self performSegueWithIdentifier:@"showCharacteristic" sender:c];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showCharacteristic"]) {
        CharacteristicViewController *c = segue.destinationViewController;
        c.characteristic = sender;
    }
}
@end
