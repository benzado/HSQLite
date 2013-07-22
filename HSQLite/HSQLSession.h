//
//  HSQLSession.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const HSQLExceptionName;
extern NSString * const HSQLErrorDomain;

extern NSString * const HSQLUnderlyingExceptionKey;

@class HSQLSession;
@class HSQLStatement;

typedef NS_OPTIONS(int, HSQLSessionFlags) {
    HSQLSessionOpenReadOnly = SQLITE_OPEN_READONLY,
    HSQLSessionOpenReadWrite = SQLITE_OPEN_READWRITE,
    HSQLSessionOpenCreate = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
};

typedef BOOL(^HSQLBusyHandler)(HSQLSession *db, int numberOfLockAttempts);

typedef void(^HSQLUndefinedCollationHandler)(HSQLSession *db, NSString *neededCollationName);

@interface HSQLSession : NSObject
{
    sqlite3 *_db;
    HSQLBusyHandler busyHandler;
    HSQLUndefinedCollationHandler collationNeededHandler;
}
+ (instancetype)sessionWithFileAtPath:(NSString *)path;
+ (instancetype)sessionWithTemporaryFile;
+ (instancetype)sessionWithMemoryDatabase;
+ (instancetype)sessionWithFileNamed:(NSString *)name;
- (instancetype)initWithPath:(NSString *)path flags:(HSQLSessionFlags)flags VFSName:(NSString *)VFSName;
- (void)close;
- (void)releaseMemory;
- (HSQLStatement *)statementWithQuery:(NSString *)sql error:(NSError **)pError;
- (BOOL)executeQuery:(NSString *)sql error:(NSError **)pError;
- (void)transactionWithBlock:(void(^)())block;
- (void)savepointWithBlock:(void(^)())block; // can be nested
- (sqlite_int64)lastInsertRowID;
- (int)numberOfRowsChangedByLastStatement;
- (int)totalNumberOfRowsChanged;
- (void)setBusyTimeout:(NSTimeInterval)timeout;
- (void)setBusyHandler:(HSQLBusyHandler)handler;
@end

/*
 Not (yet) supported:
 - commit hook
 - rollback hook
 - update hook
 - trace and profile
 - progress callback
 - authorizor callback
 - database limits
 */
