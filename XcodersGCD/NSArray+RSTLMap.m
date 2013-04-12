//
//  NSArray+RSTLMap.m
//  XcodersGCD
//
//  Created by Doug Russell on 4/9/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "NSArray+RSTLMap.h"

@implementation NSArray (RSTLMap)

- (NSArray *)rstl_map1:(id (^)(id))block
{
	NSParameterAssert(block);
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[self count]];
	for (id object in self)
	{
		id mappedObject = block(object);
		NSParameterAssert(mappedObject);
		[array addObject:mappedObject];
	}
	return [array copy];
}

//http://clang.llvm.org/docs/AutomaticReferenceCounting.html#conversion-of-pointers-to-ownership-qualified-types
static void freeStrongID(id __strong *array, NSUInteger count)
{
	NSCParameterAssert(array);
	for (NSUInteger i = 0; i < count; i++)
	{
		array[i] = nil;
	}
	free(array);
}

- (NSArray *)rstl_map2:(id (^)(id))block
{
	NSParameterAssert(block);
	NSUInteger count = [self count];
	id __strong * mappedObjects = (id __strong *)calloc(sizeof(id), count);
	NSParameterAssert(mappedObjects);
	dispatch_apply(count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t index) {
		@autoreleasepool {
			id mappedObject = block(self[index]);
			NSParameterAssert(mappedObject);
			mappedObjects[index] = mappedObject;
		}
	});
	NSArray *array = [[NSArray alloc] initWithObjects:mappedObjects count:count];
	freeStrongID(mappedObjects, count);
	return array;
}

- (NSArray *)rstl_map3:(id (^)(id))block
{
	NSParameterAssert(block);
	NSUInteger count = [self count];
	id __unsafe_unretained * objects = (id __unsafe_unretained *)calloc(sizeof(id), count);
	NSParameterAssert(objects);
	[self getObjects:objects range:NSMakeRange(0, count)];
	id __strong * mappedObjects = (id __strong *)calloc(sizeof(id), count);
	NSParameterAssert(mappedObjects);
	dispatch_apply(count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t index) {
		@autoreleasepool {
			id mappedObject = block(objects[index]);
			NSParameterAssert(mappedObject);
			mappedObjects[index] = mappedObject;
		}
	});
	free(objects);
	NSArray *array = [[NSArray alloc] initWithObjects:mappedObjects count:count];
	freeStrongID(mappedObjects, count);
	return array;
}

- (NSArray *)rstl_map4:(id (^)(id))block
{
	NSParameterAssert(block);
	NSUInteger count = [self count];
	NSFastEnumerationState state = {};
	id __unsafe_unretained objects[16];
	id __strong * mappedObjects = (id __strong *)calloc(sizeof(id), count);
	NSParameterAssert(mappedObjects);
	NSUInteger applyCount;
	size_t offset = 0;
	while ((applyCount = [self countByEnumeratingWithState:&state objects:objects count:sizeof(objects)/sizeof(*objects)]))
	{
		dispatch_apply(applyCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t index) {
			@autoreleasepool {
				id mappedObject = block(state.itemsPtr[index]);
				NSParameterAssert(mappedObject);
				mappedObjects[index+offset] = mappedObject;
			}
		});
		offset += applyCount;
	}
	NSArray *array = [[NSArray alloc] initWithObjects:mappedObjects count:count];
	freeStrongID(mappedObjects, count);
	return array;
}

@end
