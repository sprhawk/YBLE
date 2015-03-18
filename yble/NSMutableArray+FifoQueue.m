//
//  NSMutableArray+FifoQueue.m
//  yble
//
//  Created by YANG HONGBO on 2015-3-19
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import "NSMutableArray+FifoQueue.h"

@implementation NSMutableArray (FifoQueue)

- (id)pop
{
    if (self.count) {
        id o = [self firstObject];
        [self removeObject:o];
        return o;
    }
    return nil;
}

- (void)push:(id)object
{
    [self addObject:object];
}

@end
