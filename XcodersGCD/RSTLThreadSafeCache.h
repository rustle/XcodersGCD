//
//  RSTLThreadSafeCache.h
//  XcodersGCD
//
//  Created by Doug Russell on 4/11/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSTLThreadSafeCache : NSObject

- (id)objectForKey:(id<NSCopying>)key;
- (void)setObject:(id)object forKey:(id<NSCopying>)key;

- (id)objectForKeyedSubscript:(id<NSCopying>)key;
- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key;

@end
