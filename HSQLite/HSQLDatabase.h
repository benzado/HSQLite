//
//  HSQLDatabase.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const HSQLExceptionName;
extern NSString * const HSQLErrorDomain;

@class HSQLDatabase;
@class HSQLStatement;

typedef NS_OPTIONS(int, HSQLDatabaseFlags) {
    HSQLDatabaseOpenReadOnly = SQLITE_OPEN_READONLY,
    HSQLDatabaseOpenReadWrite = SQLITE_OPEN_READWRITE,
    HSQLDatabaseOpenCreate = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
};

typedef BOOL(^HSQLBusyHandler)(HSQLDatabase *db, int numberOfLockAttempts);

typedef void(^HSQLUndefinedCollationHandler)(HSQLDatabase *db, NSString *neededCollationName);

@interface HSQLDatabase : NSObject
{
    sqlite3 *_db;
    HSQLBusyHandler busyHandler;
    HSQLUndefinedCollationHandler collationNeededHandler;
}
+ (instancetype)databaseWithPath:(NSString *)path;
+ (instancetype)databaseWithTemporaryFile;
+ (instancetype)databaseInMemory;
+ (instancetype)databaseNamed:(NSString *)name;
- (instancetype)initWithPath:(NSString *)path flags:(HSQLDatabaseFlags)flags VFSName:(NSString *)VFSName;
- (void)close;
- (NSString *)absolutePath;
- (BOOL)isReadOnly;
- (void)releaseMemory;
- (HSQLStatement *)statementWithQuery:(NSString *)sql error:(NSError **)pError;
- (BOOL)executeQuery:(NSString *)sql error:(NSError **)pError;
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