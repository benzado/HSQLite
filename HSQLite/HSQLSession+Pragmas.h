//
//  HSQLSession+Pragmas.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLSession.h"

typedef NS_ENUM(int, HSQLAutoVacuumMode) {
    HSQLAutoVacuumModeOff,
    HSQLAutoVacuumModeFull,
    HSQLAutoVacuumModeIncremental
};

@interface HSQLSession (Pragmas)
@property (nonatomic) uint32_t applicationID;
@property (nonatomic) HSQLAutoVacuumMode autoVacuumMode;
@property (nonatomic) BOOL autoIndexingEnabled;
@property (nonatomic) NSStringEncoding encoding;
@property (nonatomic) BOOL foreignKeyConstraintsEnforced;
@property (nonatomic) int userVersion;
- (NSArray *)errorsFromIntegrityCheckStoppingAfter:(int)count;
- (NSArray *)errorsFromIntegrityCheck;
- (NSArray *)errorsFromQuickCheckStoppingAfter:(int)count;
- (NSArray *)errorsFromQuickCheck;
@end

// CONSIDER:
// reverse_unordered_selects
// schema_version (readonly)
// page_size

// consult http://www.sqlite.org/changes.html for version checks
// see what Base.app exposes
