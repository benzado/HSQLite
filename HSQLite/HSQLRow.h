//
//  HSQLRow.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HSQLStatement;
@protocol HSQLValue;

@interface HSQLRow : NSObject
- (id <HSQLValue>)objectAtIndexedSubscript:(NSUInteger)idx;
- (id <HSQLValue>)objectForKeyedSubscript:(NSString *)key;
@end
