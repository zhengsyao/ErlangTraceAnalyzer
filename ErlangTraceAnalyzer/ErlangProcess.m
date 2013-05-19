//
//  ErlangActor.m
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ErlangProcess.h"

@implementation ErlangProcess

@synthesize pid = _pid;
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;

- (id)initWithFrame:(NSRect)aRect
{
    self = [super initWithFrame:aRect 
                          color:[NSColor knobColor] 
                  selectedColor:[NSColor redColor]
               highlightedColor:[NSColor blueColor]];
    return self;
}

- (NSString *)description
{
    NSString *result = [NSString stringWithFormat:@"A schedule of Erlang process\n"
                        "pid : %@ \n"
                        "sched in: %lu \n"
                        "sched out: %lu \n"
                        "duration : %lu \n",
                        self.pid,
                        self.startTime,
                        self.endTime,
                        self.endTime - self.startTime];
    return result;
}

@end
