//
//  TraceDataSourceProtocol.h
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TraceDataSourceProtocol <NSObject>

// 数据访问相关的接口
- (int)getCPUCount;
- (int)getStartTime:(NSUInteger *)t1 endTime:(NSUInteger *)t2;
- (NSMutableArray *)getScheduleList;
- (NSMutableArray *)getSpawnEventList;
- (NSMutableArray *)getCacheMissesEventListInTimeRange:(NSUInteger)t1 to:(NSUInteger)t2;

@end
