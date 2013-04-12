//
//  NSArray+RSTLMap.h
//  XcodersGCD
//
//  Created by Doug Russell on 4/9/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (RSTLMap)

- (NSArray *)rstl_map1:(id (^)(id))block;
- (NSArray *)rstl_map2:(id (^)(id))block;
- (NSArray *)rstl_map3:(id (^)(id))block;
- (NSArray *)rstl_map4:(id (^)(id))block;

@end
