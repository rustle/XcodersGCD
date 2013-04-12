//
//  RSTLFileImporter.m
//  XcodersGCD
//
//  Created by Doug Russell on 4/9/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "RSTLFileImporter.h"

@interface RSTLFileImporter ()
@property (copy) NSURL *url;
@end

@implementation RSTLFileImporter

- (instancetype)initWithURL:(NSURL *)url
{
	self = [super init];
	if (self)
	{
		NSParameterAssert(url);
		_url = [url copy];
	}
	return self;
}

- (void)start
{
	NSURL *url = self.url;
	NSUInteger chunkSize = 4096;
//	NSNumber *chunkSizeObject;
//	if ([url getResourceValue:&chunkSizeObject forKey:NSURLPreferredIOBlockSizeKey error:nil])
//	{
//		chunkSize = [chunkSizeObject unsignedIntegerValue];
//	}
	NSUInteger fileSize;
	NSNumber *fileSizeObject;
	if ([url getResourceValue:&fileSizeObject forKey:NSURLFileSizeKey error:nil])
	{
		fileSize = [fileSizeObject unsignedIntegerValue];
	}
	else
	{
		return;
	}
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^(void) {
		NSFileCoordinator *coordinator = [NSFileCoordinator new];
		[coordinator coordinateReadingItemAtURL:url options:0 error:nil byAccessor:^(NSURL *newURL) {
			dispatch_io_t channel = dispatch_io_create_with_path(DISPATCH_IO_STREAM, [[url path] UTF8String], O_RDONLY, 0, queue, ^(int error) {
				
			});
			if (!channel)
			{
				return;
			}
			dispatch_semaphore_t semaphore = dispatch_semaphore_create([[NSProcessInfo processInfo] processorCount] * 2);
			dispatch_group_t group = dispatch_group_create();
			NSUInteger currentOffset = 0;
			for (currentOffset = 0; currentOffset < fileSize; currentOffset += chunkSize) 
			{
				dispatch_group_enter(group);
				dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
				dispatch_io_read(channel, currentOffset, chunkSize, dispatch_get_main_queue(), ^(bool done, dispatch_data_t data, int error){
					if (error)
					{
						dispatch_semaphore_signal(semaphore);
						dispatch_group_leave(group);
						return;
					}
					dispatch_data_apply(data, (dispatch_data_applier_t)^(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
						@autoreleasepool {
							NSString *string = [[NSString alloc] initWithBytes:buffer length:size encoding:NSUTF8StringEncoding];
							NSLog(@"%@", string);
						}
						return true;
					});
					if (done)
					{
						dispatch_semaphore_signal(semaphore);
						dispatch_group_leave(group);
					}
				});
			}
			dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
			NSLog(@"Done");
			dispatch_io_close(channel, DISPATCH_IO_STOP);
		}];
	});
}

@end
