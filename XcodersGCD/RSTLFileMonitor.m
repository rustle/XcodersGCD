//
//  RSTLFileMonitor.m
//  XcodersGCD
//
//  Created by Doug Russell on 4/9/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "RSTLFileMonitor.h"
#include <sys/fcntl.h>

@interface RSTLFileMonitor ()
@property (copy) NSURL *url;
@property NSData *bookmark; 
@property dispatch_source_t source;
@end

@implementation RSTLFileMonitor

- (instancetype)initWithURL:(NSURL *)url
{
	self = [super init];
	if (self)
	{
		NSParameterAssert(url);
		_url = [url copy];
		_bookmark = [_url bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
	}
	return self;
}

- (void)dealloc
{
	dispatch_source_t source = self.source;
	if (source && (dispatch_source_testcancel(source) == 0))
	{
		dispatch_source_cancel(source);
	}
}

- (void)start
{
	int fileHandle = open([[self.url path] UTF8String], O_EVTONLY);
	if (fileHandle == -1)
	{
		NSLog(@"Unable to open %@", self.url);
		return;
	}
	
	__weak typeof(self) weakSelf = self;
	NSURL *url = self.url;
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_source_vnode_flags_t flags = DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE;
	dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fileHandle, flags, queue);
	NSParameterAssert(source);
	self.source = source;
	dispatch_source_t weakSource = source;
	dispatch_source_set_event_handler(source, ^{
		dispatch_source_t strongSource = weakSource;
		if (strongSource)
		{
			dispatch_source_vnode_flags_t flags = dispatch_source_get_data(strongSource);
			if (flags & DISPATCH_VNODE_DELETE)
			{
				NSLog(@"%@ deleted", url);
				dispatch_source_cancel(strongSource);
				return;
			}
			if (flags & DISPATCH_VNODE_WRITE)
			{
				NSLog(@"%@ written", url);
			}
			if (flags & DISPATCH_VNODE_EXTEND)
			{
				NSLog(@"%@ size changed", url);
			}
			if (flags & DISPATCH_VNODE_ATTRIB)
			{
				NSLog(@"%@ metadata changed", url);
			}
			if (flags & DISPATCH_VNODE_LINK)
			{
				NSLog(@"%@ link count changed", url);
			}
			if (flags & DISPATCH_VNODE_RENAME)
			{
				typeof(weakSelf) strongSelf = weakSelf;
				if (strongSelf)
				{
					NSURL *currentURL = strongSelf.url;
					NSURL *newURL = [NSURL URLByResolvingBookmarkData:strongSelf.bookmark options:0 relativeToURL:nil bookmarkDataIsStale:NULL error:nil];
					strongSelf.url = newURL;
					NSLog(@"%@ renamed to %@", currentURL, newURL);
				}
			}
			if (flags & DISPATCH_VNODE_REVOKE)
			{
				NSLog(@"%@ revoked", url);
			}
		}
	});
	dispatch_source_set_cancel_handler(source, ^(void) {
		close(fileHandle);
	});
	dispatch_resume(source);
}

@end
