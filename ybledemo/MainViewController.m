//
//  MainViewController.m
//  yble
//
//  Created by YANG HONGBO on 2015-3-18.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import "MainViewController.h"
#import "ConnectViewController.h"

#import "yble.h"


@interface MainViewController ()
@property (nonatomic, strong, readwrite) NSMutableArray *array;
@property (nonatomic, strong, readwrite) YBleCentral *central;
@end

@implementation MainViewController

- (void)awakeFromNib
{
    self.array = [NSMutableArray array];
    self.central = [[YBleCentral alloc] initInMainQueueWithRestoreIdentifier:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    __weak MainViewController *SELF = self;
    self.central.stateUpdateBlock = ^(YBleState state) {
        if (YBleStatePoweredOn == state) {
            if (NO == SELF.central.isScanning) {
                [SELF.central scanForServices:nil
                                      options:nil
                                     callback:^(YBlePeripheral *peripheral) {
                                         [SELF.array addObject:peripheral];
                                         [SELF.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:SELF.array.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                     }];
            }
        }
    };
    
    if (YBleStatePoweredOn == self.central.state) {
        if (NO == SELF.central.isScanning) {
            [SELF.central scanForServices:nil
                                  options:nil
                                 callback:^(YBlePeripheral *peripheral) {
                                     [SELF.array addObject:peripheral];
                                     [SELF.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:SELF.array.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                 }];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    YBlePeripheral *p = self.array[indexPath.row];
    cell.textLabel.text = p.description;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@(%@) %@", p.name, p.advertisementData[CBAdvertisementDataLocalNameKey], p.rssi];
    if ([p.advertisementData[CBAdvertisementDataIsConnectable] boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    YBlePeripheral *p = self.array[indexPath.row];
    if ([p.advertisementData[CBAdvertisementDataIsConnectable] boolValue]) {
        [self performSegueWithIdentifier:@"showConnection" sender:p];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showConnection"]) {
        ConnectViewController *c = segue.destinationViewController;
        c.peripheral = sender;
    }
}

@end
