//
//  SpawnEvent.m
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 6/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SpawnEvent.h"

@implementation SpawnEvent

@synthesize pid = _pid;

- (NSString *)description
{
    NSString *result = [NSString stringWithFormat:@"Spawn an Erlang process\n"
                        "pid : %@ \n"
                        "spawn time: %lu ",
                        self.pid,
                        self.timeStamp];
    return result;
}


@end
