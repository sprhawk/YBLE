//
//  CharacteristicViewController.m
//  yble
//
//  Created by YANG HONGBO on 2015-3-19.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import "CharacteristicViewController.h"

@interface CharacteristicViewController () <UITableViewDataSource, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong, readwrite) NSMutableArray *array;
- (IBAction)readValue:(id)sender;

@end

@implementation CharacteristicViewController

- (void)awakeFromNib
{
    self.array = [NSMutableArray array];
}

- (IBAction)readValue:(id)sender {
    __weak CharacteristicViewController *SELF = self;
    [self.characteristic readValue:^(NSData *data, NSError *error) {
        [SELF.array addObject:[NSString stringWithFormat:@"read %@", data]];
        [SELF.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:SELF.array.count - 1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
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
    cell.textLabel.text = self.array[indexPath.row];
    return cell;
}

@end
