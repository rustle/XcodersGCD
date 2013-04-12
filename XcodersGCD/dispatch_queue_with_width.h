//
//  dispatch_queue_with_width.h
//  XcodersGCD
//
//  Created by Doug Russell on 4/11/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

// creates a queue that can be used with the other rstl_ dispatch api
extern dispatch_queue_t rstl_queue_create(const char *label, long width);
// Same as dispatch_async, but respects the queues width
extern void rstl_async(dispatch_queue_t queue, dispatch_block_t block);
// Same as dispatch_group_wait
extern long rstl_queue_wait(dispatch_queue_t queue, dispatch_time_t timeout);
// Same as dispatch_group_notify
extern void rstl_queue_notify(dispatch_queue_t queue, dispatch_block_t block);
