//
//  HSQLBackupSession.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/9/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLBackupSession.h"
#import "HSQLSession+Private.h"

@implementation HSQLBackupSession

- (id)initWithSQLite3Backup:(sqlite3_backup *)backup
{
    if ((self = [super init])) {
        _backup = backup;
        _progressNotificationInterval = 0.5;
    }
    return self;
}

- (void)dealloc
{
    [self finish];
}

- (int)totalNumberOfPages
{
    if (_backup == NULL) return 0;
    return sqlite3_backup_pagecount(_backup);
}

- (int)remainingNumberOfPages
{
    if (_backup == NULL) return 0;
    return sqlite3_backup_remaining(_backup);
}

- (float)progress
{
    if (_backup == NULL) return 1.0;
    float n = sqlite3_backup_remaining(_backup);
    float d = sqlite3_backup_pagecount(_backup);
    return ((d - n) / d);
}

- (void)finish
{
    if (_backup) {
        sqlite3_backup_finish(_backup);
        _backup = NULL;
    }
}

- (BOOL)copyPagesBatchOfSize:(int)batchSize error:(NSError **)error
{
    if (_backup == NULL) return YES;
    if (error) *error = nil;
    int r = sqlite3_backup_step(_backup, batchSize);
    switch (r) {
        case SQLITE_OK:
            return NO;
        case SQLITE_DONE:
            [self finish];
            return YES;
        case SQLITE_LOCKED:
        case SQLITE_BUSY:
            // non-fatal errors, try again later
            return NO;
        default: {
            [HSQLSession raiseExceptionOrGetError:error forResultCode:r];
            return YES;
        }
    }
}

- (BOOL)copyAllRemainingPagesError:(NSError **)error
{
    return [self copyPagesBatchOfSize:-1 error:error];
}

- (BOOL)copyPagesForDuration:(NSTimeInterval)duration error:(NSError *__autoreleasing *)error
{
    int batchSize;
    if (copyingDuration == 0) {
        batchSize = 16;
    } else {
        double pagesCopied = self.totalNumberOfPages - self.remainingNumberOfPages;
        double pagesPerSecond = pagesCopied / copyingDuration;
        batchSize = MAX(1, ceil(pagesPerSecond * duration));
    }
    CFAbsoluteTime beginTime = CFAbsoluteTimeGetCurrent();
    BOOL done = [self copyPagesBatchOfSize:batchSize error:error];
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    copyingDuration += (endTime - beginTime);
    return done;
}

typedef void((^HSQLRecursiveBlock)(id));

- (void)copyPagesOnQueue:(dispatch_queue_t)queue progressHandler:(void(^)())progressHandler completionHandler:(void(^)(NSError *error))completionHandler
{
    HSQLRecursiveBlock step = [^(HSQLRecursiveBlock next) {
        NSError *error = nil;
        if ([self copyPagesForDuration:self.progressNotificationInterval error:&error]) {
            completionHandler(error);
        } else {
            progressHandler();
            dispatch_async(queue, ^{
                next(next);
            });
        }
    } copy];
    dispatch_async(queue, ^{
        step(step);
    });
}

- (void)copyPagesAsynchronouslyWithProgressHandler:(void(^)())progressHandler completionHandler:(void(^)(NSError *error))completionHandler
{
    [self copyPagesOnQueue:dispatch_get_main_queue() progressHandler:progressHandler completionHandler:completionHandler];
}

@end

@implementation HSQLSession (Backup)

- (HSQLBackupSession *)backupSessionWithSourceName:(NSString *)sourceName destinationDatabase:(HSQLSession *)destinationDatabase name:(NSString *)destinationName
{
    const char *src = [sourceName UTF8String];
    const char *dst = [destinationName UTF8String];
    sqlite3_backup *backup = sqlite3_backup_init(destinationDatabase->_db, dst, _db, src);
    if (backup) {
        return [[HSQLBackupSession alloc] initWithSQLite3Backup:backup];
    } else {
        [destinationDatabase raiseExceptionOrGetError:NULL];
        return nil;
    }
}

- (HSQLBackupSession *)backupSessionWithDestinationDatabase:(HSQLSession *)destinationDatabase
{
    return [self backupSessionWithSourceName:@"main" destinationDatabase:destinationDatabase name:@"main"];
}

@end
