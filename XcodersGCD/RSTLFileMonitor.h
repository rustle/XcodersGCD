//
//  RSTLFileMonitor.h
//  XcodersGCD
//
//  Created by Doug Russell on 4/9/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSTLFileMonitor : NSObject

- (instancetype)initWithURL:(NSURL *)url;
- (void)start;

@end
