//
//  SpawnEvent.h
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 6/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PointEvent.h"

@interface SpawnEvent : PointEvent

@property (strong) NSString *pid;

@end
