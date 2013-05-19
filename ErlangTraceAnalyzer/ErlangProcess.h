//
//  ErlangActor.h
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TraceeObject.h"

@interface ErlangProcess : TraceeObject
@property (nonatomic, strong) NSString *pid;
@property NSUInteger startTime;
@property NSUInteger endTime;

- (id)initWithFrame:(NSRect)aRect;

@end
