//
//  HSQLDatabase+Private.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/8/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#ifndef HSQLite_HSQLDatabase_Private_h
#define HSQLite_HSQLDatabase_Private_h

@interface HSQLDatabase (Private)
- (void)raiseException;
- (int)busyForNumberOfLockAttempts:(int)attempts;
- (void)collationNeededWithName:(NSString *)name;
@end

#endif
