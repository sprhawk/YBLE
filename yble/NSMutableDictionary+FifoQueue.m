//
//  NSMutableDictionary+FifoQueue.m
//  yble
//
//  Created by YANG HONGBO on 2015-3-19.
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import "NSMutableDictionary+FifoQueue.h"
#import "NSMutableArray+FifoQueue.h"

@implementation NSMutableDictionary (FifoQueue)

- (void)pushObject:(id)object inQueue:(id <NSCopying>)queueKey
{
    NSMutableArray *queue = self[queueKey];
    if (nil == queue) {
        queue = [NSMutableArray arrayWithCapacity:1];
        self[queueKey] = queue;
    }
    [queue push:object];
}

- (id)popObjectInQueue:(id <NSCopying>)queueKey
{
    NSMutableArray *queue = self[queueKey];
    if (queue) {
        return [queue pop];
    }
    return nil;
}

@end
