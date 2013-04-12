//
//  RSTLOperationQueue.h
//  XcodersGCD
//
//  Created by Doug Russell on 4/9/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSTLOperationQueue : NSObject

@property NSInteger maxConcurrentOperationCount;

- (void)addAsyncOperationWithBlock:(void (^)(void))block;
- (void)addSyncOperationWithBlock:(void (^)(void))block;

- (void)addBarrierAsyncOperationWithBlock:(void (^)(void))block;
- (void)addBarrierSyncOperationWithBlock:(void (^)(void))block;

- (void)waitUntilAllOperationsAreFinished;
- (void)notifyWhenAllOperationsAreFinished:(void (^)(void))block;

@end
