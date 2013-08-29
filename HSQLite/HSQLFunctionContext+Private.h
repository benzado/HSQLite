//
//  HSQLFunctionContext+Private.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/8/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#ifndef HSQLite_HSQLFunctionContext_Private_h
#define HSQLite_HSQLFunctionContext_Private_h

@interface HSQLFunctionContext (Private)
- (instancetype)initWithContext:(sqlite3_context *)context arguments:(sqlite3_value **)argv count:(int)argc;
- (void)invalidate;
- (BOOL)didReturn;
@end

#endif
