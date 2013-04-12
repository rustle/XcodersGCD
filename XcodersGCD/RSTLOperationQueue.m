//
//  RSTLOperationQueue.m
//  XcodersGCD
//
//  Created by Doug Russell on 4/9/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "RSTLOperationQueue.h"

@interface RSTLOperationQueue ()

@property (nonatomic) dispatch_queue_t waitQueue;
@property (nonatomic) dispatch_queue_t workQueue;
@property (nonatomic) dispatch_group_t group;
@property (nonatomic) NSRecursiveLock *widthLock;

@property dispatch_semaphore_t widthSemaphore;

@end

@implementation RSTLOperationQueue
@synthesize maxConcurrentOperationCount=_maxConcurrentOperationCount;
@synthesize widthSemaphore=_widthSemaphore;

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		dispatch_queue_t hiPriorityQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
		NSParameterAssert(hiPriorityQueue);
		_waitQueue = dispatch_queue_create("com.rstl.operationqueue.waitqueue", DISPATCH_QUEUE_SERIAL);
		NSParameterAssert(_waitQueue);
		dispatch_set_target_queue(_waitQueue, hiPriorityQueue);
		_workQueue = dispatch_queue_create("com.rstl.operationqueue.workqueue", DISPATCH_QUEUE_CONCURRENT);
		NSParameterAssert(_workQueue);
		dispatch_set_target_queue(_workQueue, hiPriorityQueue);
		_group = dispatch_group_create();
		NSParameterAssert(_group);
		_widthLock = [NSRecursiveLock new];
		NSParameterAssert(_widthLock);
	}
	return self;
}

- (void)addAsyncOperationWithBlock:(void (^)(void))block
{
	NSParameterAssert(block);
	// 
	dispatch_group_t group = self.group;
	dispatch_group_enter(group);
	// 
	dispatch_queue_t workQueue = self.workQueue;
	// See if there's a width to enforce
	dispatch_semaphore_t widthSemaphore = self.widthSemaphore;
	if (widthSemaphore)
	{
		dispatch_queue_t waitQueue = self.waitQueue;
		dispatch_async(waitQueue, ^{
			dispatch_semaphore_wait(widthSemaphore, DISPATCH_TIME_FOREVER);
			dispatch_async(workQueue, ^{
				block();
				dispatch_semaphore_signal(widthSemaphore);
				dispatch_group_leave(group);
			});
		});
	}
	else
	{
		dispatch_async(workQueue, ^{
			block();
			dispatch_group_leave(group);
		});
	}
}

- (void)addSyncOperationWithBlock:(void (^)(void))block
{
	NSParameterAssert(block);
	// 
	dispatch_group_t group = self.group;
	dispatch_group_enter(group);
	// 
	dispatch_queue_t workQueue = self.workQueue;
	// See if there's a width to enforce
	dispatch_semaphore_t widthSemaphore = self.widthSemaphore;
	if (widthSemaphore)
	{
		dispatch_semaphore_wait(widthSemaphore, DISPATCH_TIME_FOREVER);
		dispatch_sync(workQueue, ^{
			block();
			dispatch_semaphore_signal(widthSemaphore);
			dispatch_group_leave(group);
		});
	}
	else
	{
		dispatch_sync(workQueue, ^{
			block();
			dispatch_group_leave(group);
		});
	}
}

- (void)addBarrierAsyncOperationWithBlock:(void (^)(void))block
{
	NSParameterAssert(block);
	// 
	dispatch_group_t group = self.group;
	dispatch_group_enter(group);
	// 
	dispatch_queue_t workQueue = self.workQueue;
	dispatch_barrier_async(workQueue, ^{
		block();
		dispatch_group_leave(group);
	});
}

- (void)addBarrierSyncOperationWithBlock:(void (^)(void))block
{
	NSParameterAssert(block);
	// 
	dispatch_group_t group = self.group;
	dispatch_group_enter(group);
	// 
	dispatch_queue_t workQueue = self.workQueue;
	dispatch_barrier_sync(workQueue, ^{
		block();
		dispatch_group_leave(group);
	});
}

- (void)waitUntilAllOperationsAreFinished
{
	dispatch_group_t group = self.group;
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

- (void)notifyWhenAllOperationsAreFinished:(void (^)(void))block
{
	dispatch_group_t group = self.group;
	dispatch_queue_t workQueue = self.workQueue;
	dispatch_group_notify(group, workQueue, block);
}

- (NSInteger)maxConcurrentOperationCount
{
	NSInteger max;
	NSRecursiveLock *widthLock = self.widthLock;
	[widthLock lock];
	max = _maxConcurrentOperationCount;
	[widthLock unlock];
	return max;
}

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount
{
	NSRecursiveLock *widthLock = self.widthLock;
	[widthLock lock];
	if (_maxConcurrentOperationCount != maxConcurrentOperationCount)
	{
		_maxConcurrentOperationCount = maxConcurrentOperationCount;
		_widthSemaphore = dispatch_semaphore_create(_maxConcurrentOperationCount);
	}
	[widthLock unlock];
}

- (dispatch_semaphore_t)widthSemaphore
{
	dispatch_semaphore_t widthSemaphore;
	NSRecursiveLock *widthLock = self.widthLock;
	[widthLock lock];
	widthSemaphore = _widthSemaphore;
	[widthLock unlock];
	return widthSemaphore;
}

- (void)setWidthSemaphore:(dispatch_semaphore_t)widthSemaphore
{
	NSParameterAssert(NO);
}

@end
