//
//  NSMutableArray+FifoQueue.h
//  yble
//
//  Created by YANG HONGBO on 2015-3-19
//  Copyright (c) 2015年 Yang.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (FifoQueue)
- (id)pop;
- (void)push:(id)object;
@end
