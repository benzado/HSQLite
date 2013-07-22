//
//  HSQLSession+Private.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/8/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#ifndef HSQLite_HSQLSession_Private_h
#define HSQLite_HSQLSession_Private_h

@interface HSQLSession (Private)
+ (BOOL)raiseExceptionOrGetError:(NSError **)error forResultCode:(int)resultCode;
- (void)raiseExceptionOrGetError:(NSError **)error;
- (int)busyForNumberOfLockAttempts:(int)attempts;
- (void)collationNeededWithName:(NSString *)name;
- (sqlite3 *)handle;
@end

#endif
