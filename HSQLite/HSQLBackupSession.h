//
//  HSQLBackupSession.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/9/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HSQLite/HSQLSession.h>

@interface HSQLBackupSession : NSObject
{
    sqlite3_backup *_backup;
    CFTimeInterval copyingDuration;
}
@property (nonatomic,readonly) int totalNumberOfPages;
@property (nonatomic,readonly) int remainingNumberOfPages;
@property (nonatomic,readonly) float progress;
@property (nonatomic) NSTimeInterval progressNotificationInterval;
- (BOOL)copyPagesBatchOfSize:(int)batchSize error:(NSError **)error;
- (BOOL)copyPagesForDuration:(NSTimeInterval)duration error:(NSError *__autoreleasing *)error;
- (BOOL)copyAllRemainingPagesError:(NSError **)error;
- (void)copyPagesOnQueue:(dispatch_queue_t)queue progressHandler:(void(^)())progressHandler completionHandler:(void(^)(NSError *error))completionHandler;
- (void)copyPagesAsynchronouslyWithProgressHandler:(void(^)())progressHandler completionHandler:(void(^)(NSError *error))completionHandler;
@end

@interface HSQLSession (Backup)
- (HSQLBackupSession *)backupSessionWithDestinationDatabase:(HSQLSession *)destinationDatabase;
@end
