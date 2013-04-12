//
//  RSTLThreadSafeCache.m
//  XcodersGCD
//
//  Created by Doug Russell on 4/11/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "RSTLThreadSafeCache.h"

@interface RSTLThreadSafeCache ()
@property (nonatomic) NSMutableDictionary *cache;
@property (nonatomic) dispatch_queue_t queue;
@end

@implementation RSTLThreadSafeCache

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		_cache = [NSMutableDictionary new];
		_queue = dispatch_queue_create("com.RSTL.threadsafecachequeue", DISPATCH_QUEUE_SERIAL);
		dispatch_set_target_queue(_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
	}
	return self;
}

- (id)objectForKey:(id<NSCopying>)key
{
	NSParameterAssert(key);
	__block id object;
	dispatch_sync(self.queue, ^{
		object = self.cache[key];
	});
	return object;
}

- (void)setObject:(id)object forKey:(id<NSCopying>)key
{
	NSParameterAssert(object);
	NSParameterAssert(key);
	dispatch_sync(self.queue, ^{
		self.cache[key] = object;
	});
}

- (id)objectForKeyedSubscript:(id)key
{
	return [self objectForKey:key];
}

- (void)setObject:(id)object forKeyedSubscript:(id <NSCopying>)key
{
	[self setObject:object forKey:key];
}

@end
