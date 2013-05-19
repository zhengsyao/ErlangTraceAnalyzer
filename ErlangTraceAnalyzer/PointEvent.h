//
//  PointEvent.h
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 6/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TraceeObject.h"

@interface PointEvent : TraceeObject
@property NSUInteger timeStamp;

- (id)initWithFrame:(NSRect)aRect;

@end
