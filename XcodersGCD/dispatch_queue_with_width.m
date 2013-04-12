//
//  dispatch_queue_with_width.m
//  XcodersGCD
//
//  Created by Doug Russell on 4/11/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "dispatch_queue_with_width.h"

static const void * rstl_queue_context_key = "rstl_queue_context_key";

@interface RSTLQueueContext : NSObject

- (instancetype)initWithWidth:(long)width;
- (dispatch_queue_t)syncQueue;
- (dispatch_semaphore_t)semaphore;
- (dispatch_group_t)group;

@end

static void _rstl_queue_finalizer(void *context)
{
	CFRelease((CFTypeRef)context);
}

static RSTLQueueContext * _rstl_lookup_context(dispatch_queue_t queue)
{
	RSTLQueueContext *context;
	context = (__bridge RSTLQueueContext *)dispatch_queue_get_specific(queue, rstl_queue_context_key);
	return context;
}

dispatch_queue_t rstl_queue_create(const char *label, long width)
{
	if (width <= 0)
	{
		NSLog(@"Attempted to create a dispatch queue with a width of zero or less");
		return NULL;
	}
	dispatch_queue_t queue = dispatch_queue_create(label, DISPATCH_QUEUE_CONCURRENT);
	RSTLQueueContext *context = [[RSTLQueueContext alloc] initWithWidth:width];
	void * contextRef;
	contextRef = (void *)CFBridgingRetain(context);
	dispatch_queue_set_specific(queue, rstl_queue_context_key, contextRef, &_rstl_queue_finalizer);
	return queue;
}

#define _rstl_dispatch_func_preflight \
if (queue == NULL) \
{ \
	NSLog(@"Attempted to schedule a block on a NULL queue"); \
	return; \
} \
if (block == NULL) \
{ \
	NSLog(@"Attempted to schedule a NULL block"); \
	return; \
}

void _rstl_dispatch_async_func(dispatch_queue_t queue, dispatch_block_t block, void (*async_func)(dispatch_queue_t queue, dispatch_block_t block))
{
	_rstl_dispatch_func_preflight
	NSCParameterAssert(async_func);
	RSTLQueueContext *context = _rstl_lookup_context(queue);
	dispatch_queue_t syncQueue = context.syncQueue;
	dispatch_semaphore_t semaphore = context.semaphore;
	dispatch_group_t group = context.group;
	if (semaphore && syncQueue && group)
    {
		dispatch_group_enter(group);
        dispatch_async(syncQueue, ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            async_func(queue, ^ {
                block();
                dispatch_semaphore_signal(semaphore);
                dispatch_group_leave(group);
            });
        });
    }
    else
    {
        async_func(queue, block);
    }
}

void _rstl_dispatch_sync_func(dispatch_queue_t queue, dispatch_block_t block, void (*sync_func)(dispatch_queue_t queue, dispatch_block_t block))
{
	_rstl_dispatch_func_preflight
	NSCParameterAssert(sync_func);
	RSTLQueueContext *context = _rstl_lookup_context(queue);
	dispatch_semaphore_t semaphore = context.semaphore;
	dispatch_group_t group = context.group;
	if (semaphore && group)
    {
		dispatch_group_enter(group);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
		sync_func(queue, ^ {
			block();
			dispatch_semaphore_signal(semaphore);
			dispatch_group_leave(group);
		});
    }
    else
    {
        sync_func(queue, block);
    }
}

void rstl_async(dispatch_queue_t queue, dispatch_block_t block)
{
	_rstl_dispatch_async_func(queue, block, &dispatch_async);
}

void rstl_sync(dispatch_queue_t queue, dispatch_block_t block)
{
	_rstl_dispatch_sync_func(queue, block, &dispatch_sync);
}

void rstl_barrier_async(dispatch_queue_t queue, dispatch_block_t block)
{
	_rstl_dispatch_async_func(queue, block, &dispatch_barrier_async);
}

void rstl_barrier_sync(dispatch_queue_t queue, dispatch_block_t block)
{
	_rstl_dispatch_sync_func(queue, block, &dispatch_barrier_sync);
}

long rstl_queue_wait(dispatch_queue_t queue, dispatch_time_t timeout)
{
	if (queue == NULL)
	{
		NSLog(@"Attempted to wait on a NULL queue");
		return 0;
	}
	RSTLQueueContext *context = _rstl_lookup_context(queue);
	dispatch_group_t group = context.group;
	if (group) 
	{
		return dispatch_group_wait(group, timeout);
	}
	return 0;
}

void es_queue_notify(dispatch_queue_t queue, dispatch_block_t block)
{
	if (queue == NULL)
	{
		NSLog(@"Attempted to schedule a notify block on a NULL queue");
		return;
	}
	if (block == NULL)
	{
		NSLog(@"Attempted to schedule a NULL notify block");
		return;
	}
	RSTLQueueContext *context = _rstl_lookup_context(queue);
	dispatch_group_t group = context.group;
	if (group) 
	{
		return dispatch_group_notify(group, queue, block);
	}
}

@implementation RSTLQueueContext
{
	dispatch_queue_t _syncQueue;
	dispatch_semaphore_t _semaphore;
	dispatch_group_t _group;
}

- (instancetype)initWithWidth:(long)width
{
	self = [super init];
	if (self)
	{
		_syncQueue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL);
		_semaphore = dispatch_semaphore_create(width);
		_group = dispatch_group_create();
	}
	return self;
}

- (dispatch_queue_t)syncQueue { return _syncQueue; }

- (dispatch_semaphore_t)semaphore { return _semaphore; }

- (dispatch_group_t)group { return _group; }

@end
