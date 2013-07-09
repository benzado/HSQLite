//
//  HSQLRow+Private.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/8/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#ifndef HSQLite_HSQLRow_Private_h
#define HSQLite_HSQLRow_Private_h

@interface HSQLRow (Private)
- (instancetype)initWithStatement:(HSQLStatement *)statement stmt:(sqlite3_stmt *)stmt;
@end

#endif
