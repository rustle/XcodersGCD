//
//  main.m
//  XcodersGCD
//
//  Created by Doug Russell on 4/9/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSTLOperationQueue.h"
#import "NSArray+RSTLMap.h"
#import "RSTLFileMonitor.h"
#import "RSTLFileImporter.h"

static void import()
{
	RSTLFileImporter *importer = [[RSTLFileImporter alloc] initWithURL:[NSURL fileURLWithPath:[@"loremipsum.txt" stringByExpandingTildeInPath]]];
	[importer start];
	dispatch_main();
}

static void monitor()
{
	RSTLFileMonitor *monitor = [[RSTLFileMonitor alloc] initWithURL:[NSURL fileURLWithPath:[@"loremipsum.txt" stringByExpandingTildeInPath]]];
	[monitor start];
	dispatch_main();
}

static void map()
{
	NSArray *strings = @[@"0", @"1", @"2", @"3", @"4"];
	NSArray *numbers1 = [strings rstl_map1:^id(id object) {
		return @([object integerValue]);
	}];
	NSArray *numbers2 = [strings rstl_map2:^id(id object) {
		return @([object integerValue]);
	}];
	NSArray *numbers3 = [strings rstl_map3:^id(id object) {
		return @([object integerValue]);
	}];
	NSArray *numbers4 = [strings rstl_map4:^id(id object) {
		return @([object integerValue]);
	}];
	NSLog(@"%@ %@ %@ %@ %@", strings, numbers1, numbers2, numbers3, numbers4);
}

static void queue()
{
	NSLog(@"Start");
	RSTLOperationQueue *queue = [RSTLOperationQueue new];
	[queue setMaxConcurrentOperationCount:2];
	for (int i = 0; i < 20; i++)
	{
		NSLog(@"Add Async %d", i);
		[queue addAsyncOperationWithBlock:^{
			NSLog(@"Start Perform Async %d", i);
			sleep(2);
			NSLog(@"End Perform Async %d", i);
		}];
	}
	[queue addBarrierAsyncOperationWithBlock:^{
		NSLog(@"Perform Barrier Async");
	}];
	[queue notifyWhenAllOperationsAreFinished:^{
		NSLog(@"Done");
	}];
	dispatch_main();
}

int main(int argc, const char * argv[])
{
	@autoreleasepool {
//		queue();
//		map();
//		monitor();
//		import();
	}
	return 0;
}
