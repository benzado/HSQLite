//
//  HSQLDatabase+Pragmas.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLDatabase.h"

typedef NS_ENUM(int, HSQLAutoVacuumMode) {
    HSQLAutoVacuumModeOff,
    HSQLAutoVacuumModeFull,
    HSQLAutoVacuumModeIncremental
};

@interface HSQLDatabase (Pragmas)
@property (nonatomic) uint32_t applicationID;
@property (nonatomic) HSQLAutoVacuumMode autoVacuumMode;
@property (nonatomic) BOOL autoIndexingEnabled;
@property (nonatomic) NSStringEncoding encoding;
@property (nonatomic) BOOL foreignKeyConstraintsEnforced;
@property (nonatomic) int userVersion;
@end

// CONSIDER:
// integrity_check
// journal_mode
// quick_check
// reverse_unordered_selects
// schema_version (readonly)
// secure_delete

// consult http://www.sqlite.org/changes.html for version checks
// see what Base.app exposes
