//
//  HSQLDatabase+Collations.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLDatabase.h"

@interface HSQLDatabase (Collations)
- (void)defineCollationNamed:(NSString *)name comparator:(NSComparator)comparator;
- (void)removeCollationNamed:(NSString *)name;
- (NSArray *)allCollationNames;
- (void)setUndefinedCollationHandler:(HSQLUndefinedCollationHandler)handler;
@end
