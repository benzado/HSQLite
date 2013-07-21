//
//  HSQLStatement+Private.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/8/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#ifndef HSQLite_HSQLStatement_Private_h
#define HSQLite_HSQLStatement_Private_h

@interface HSQLStatement (Private)
- (instancetype)initWithSession:(HSQLSession *)session stmt:(sqlite3_stmt *)stmt;
@end

#endif
