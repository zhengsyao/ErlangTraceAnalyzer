//
//  AppController.m
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

/*
 数据库表的schema
 */

#import "AppController.h"

static NSCharacterSet *newlineSet;
static NSCharacterSet *whitespaceSet;

@implementation AppController {
    // 数据库相关的成员变量
    sqlite3 *traceDb;
    NSString *traceDbPath;
    NSString *traceFilePath;
    
    // 控制数据缓存的成员变量
    BOOL hasGetCPUCount;
    BOOL hasGetSchedulerList;
    BOOL hasGetStartEndTimes;
    BOOL hasGetSpawnEventList;
}

@synthesize traceView = _traceView;
@synthesize selectedItemDescription = _selectedItemDescription;
@synthesize savePDFButton = _savePDFButton;

- (void)reset
{
    // 用于比较用的字符集
    newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];
    whitespaceSet = [NSCharacterSet characterSetWithCharactersInString:@" \t"];
    
    // 控制数据缓存的成员变量
    hasGetCPUCount = NO;
    hasGetSchedulerList = NO;
    hasGetStartEndTimes = NO;
    hasGetSpawnEventList = NO;
    
    // 设置视图
    self.traceView.dataSource = self;
}

- (void)awakeFromNib
{
    [self reset];
}

- (IBAction)loadPressed:(NSButton *)sender 
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel beginSheetModalForWindow:[NSApp mainWindow]
                      completionHandler:^(NSInteger result) {
                          if (result == NSFileHandlingPanelOKButton) {
                              traceFilePath = [[openPanel URL] path];
                              [self reset];
                              [self loadTraceFile:traceFilePath];
                              [self.savePDFButton setEnabled:YES];
                          }
                      }
     ];    
}

- (IBAction)zoomInPressed:(NSButton *)sender {
    [self.traceView zoom:traceViewZoomIn];
}

- (IBAction)zoomOutPressed:(NSButton *)sender {
    [self.traceView zoom:traceViewZoomOut];
}

- (IBAction)highRelatedEventsPressed:(NSButton *)sender {
    [self.traceView highlightEventsAccordingToCurrentSelected];
    [self.traceView setNeedsDisplay:YES];
}

- (IBAction)savePDFPressed:(NSButton *)sender {
    NSString *pdfFilePath = [[traceFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    NSData *pdfData = [self.traceView dataWithPDFInsideRect:self.traceView.frame];
    [pdfData writeToFile:pdfFilePath atomically:YES];
}

- (void)loadTraceFile:(NSString *)filePath
{
    // 生成数据库的路径
    traceDbPath = [[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"db"];
    NSLog(@"Loading file %@", traceFilePath);
    NSString *traceFileContent = [NSString stringWithContentsOfFile:traceFilePath encoding:NSASCIIStringEncoding error:NULL];
    [self parseTraceFile:traceFileContent];
    
    [self.traceView loadNewData];
}

- (BOOL)parseTraceFile:(NSString *)fileContent
{
    int rc;
    char *sql;
    char *zErr;
    // 初始化sqlite3数据库。如果数据库不存在，则创建数据库，如果存在，则直接打开数据库
    if (access([traceDbPath cStringUsingEncoding:NSASCIIStringEncoding], R_OK)) {
        // 数据库文件不存在，创建数据库文件
        NSLog(@"DB file not exist, create it");
        rc = sqlite3_open_v2([traceDbPath cStringUsingEncoding:NSASCIIStringEncoding], 
                             &traceDb, 
                             SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
                             NULL);
        if (rc != SQLITE_OK) {
            NSLog(@"sqlite3 database create error");
            return NO;
        }
        
        // 创建数据库表
        sql = "create table traceEvents (cpuid integer not null,"
        "ts integer not null, "
        "eventName text not null,"
        "pid1 text default null,"
        "pid2 text default null,"
        "extra text default null"
        ");"
        "create index cpuid_idx on traceEvents(cpuid);"
        "create index ts_idx on traceEvents(ts);"
        "create index ename_idx on traceEvents(eventName);";
        rc = sqlite3_exec(traceDb, sql, NULL, NULL, &zErr);
        if (rc != SQLITE_OK) {
            NSLog(@"sqlite3 database create table error: %s", zErr);
            sqlite3_free(zErr);
            return NO;
        }
        
        // 读取文件，将记录写入数据库
        rc = sqlite3_exec(traceDb, "BEGIN TRANSACTION", NULL, NULL, &zErr);
        if (rc != SQLITE_OK) {
            NSLog(@"sqlite3 database BEGIN TRANSACTION error: %s", zErr);
            sqlite3_free(zErr);
            return NO;
        }
        NSLog(@"Parsing trace file and saving trace events to database");
        NSArray *traceLines = [fileContent componentsSeparatedByCharactersInSet:newlineSet];
        for (NSString *line in traceLines) {
            NSString *trimmedLine = [line stringByTrimmingCharactersInSet:whitespaceSet]; 
            if ([trimmedLine length] == 0) {
                continue;
            }
            if ([trimmedLine characterAtIndex:0] == '%') {
                continue;
            }
            NSArray *eventParts = [trimmedLine componentsSeparatedByString:@"|"];
            NSUInteger cpuId = [[eventParts objectAtIndex:0] integerValue];
            NSUInteger ts = [[eventParts objectAtIndex:1] longLongValue];
            NSString *eventName = [eventParts objectAtIndex:2];
            NSString *pid1;
            NSString *pid2;
            NSString *extra;
            if ([eventName isEqualToString:@"schedule"]) {
                pid1 = [eventParts objectAtIndex:3];
                pid2 = @"NULL";
                extra = @"NULL";
            } else if ([eventName isEqualToString:@"unschedule"]) {
                pid1 = [eventParts objectAtIndex:3];
                pid2 = @"NULL";
                extra = @"NULL";
            } else if ([eventName isEqualToString:@"send"]) {
                pid1 = [eventParts objectAtIndex:3];
                pid2 = [eventParts objectAtIndex:4];
                extra = @"NULL";
            } else if ([eventName isEqualToString:@"queued"]) {
                pid1 = [eventParts objectAtIndex:3];
                pid2 = @"NULL";
                extra = @"NULL";
            } else if ([eventName isEqualToString:@"receive"]) {
                pid1 = [eventParts objectAtIndex:3];
                pid2 = @"NULL";
                extra = @"NULL";
            } else if ([eventName isEqualToString:@"spawn"]) {
                pid1 = [eventParts objectAtIndex:3];
                pid2 = @"NULL";
                extra = @"NULL";
            } else if ([eventName isEqualToString:@"exit"]) {
                pid1 = [eventParts objectAtIndex:3];
                pid2 = @"NULL";
                extra = @"NULL";
            } else if ([eventName isEqualToString:@"cache_miss_count"]) {
                pid1 = @"NULL";
                pid2 = @"NULL";
                extra = @"NULL";
            } else {
                continue;
            }
            NSString *insertSql = [NSString stringWithFormat:@"insert into traceEvents "
                                   "values (%lu, %lu, '%@', '%@', '%@', '%@')",
                                   cpuId,
                                   ts,
                                   eventName,
                                   pid1,
                                   pid2,
                                   extra];
            rc = sqlite3_exec(traceDb, [insertSql cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL, &zErr);
            if (rc != SQLITE_OK) {
                NSLog(@"sqlite3 insert error: %s. \n sql:%@", zErr, insertSql);
                sqlite3_free(zErr);
                return NO;
            }
        }
        rc = sqlite3_exec(traceDb, "COMMIT TRANSACTION", NULL, NULL, &zErr);
        if (rc != SQLITE_OK) {
            NSLog(@"sqlite3 database COMMIT TRANSACTION error: %s", zErr);
            sqlite3_free(zErr);
            return NO;
        }
    } else {
        // 打开数据库文件
        NSLog(@"DB file exists, open it");
        rc = sqlite3_open_v2([traceDbPath UTF8String], 
                             &traceDb, 
                             SQLITE_OPEN_READWRITE,
                             NULL);
        if (rc != SQLITE_OK) {
            NSLog(@"sqlite3 database open error");
            return NO;
        }
    }
    
    return YES;
}

- (int)getCPUCount
{
    static int cpuCount = -1;
    if (hasGetCPUCount) {
        return cpuCount;
    }
    
    NSString *sql = @"select max(cpuid) from traceEvents";
    int rc, nRows, nCols;
    char **result;
    char *zErr;
    rc = sqlite3_get_table(traceDb, 
                           [sql cStringUsingEncoding:NSASCIIStringEncoding], 
                           &result, 
                           &nRows,
                           &nCols, 
                           &zErr);
    if (rc != SQLITE_OK) {
        NSLog(@"sqlite3 query error: %s. \n sql:%@", zErr, sql);
        sqlite3_free(zErr);
        return 0;
    }
    if (nRows != 1) {
        return 0;
    }
    cpuCount = atoi(result[1]) + 1;
    sqlite3_free_table(result);
    
    hasGetCPUCount = YES;
    return cpuCount;
}

- (int)getStartTime:(NSUInteger *)t1 endTime:(NSUInteger *)t2
{
    static NSUInteger startTime = 0;
    static NSUInteger endTime = 0;
    if (hasGetStartEndTimes) {
        *t1 = startTime;
        *t2 = endTime;
        return 0;
    }
    
    NSString *sql = @"select min(ts), max(ts) from traceEvents";
    int rc, nRows, nCols;
    char **result;
    char *zErr;
    rc = sqlite3_get_table(traceDb, 
                           [sql cStringUsingEncoding:NSASCIIStringEncoding], 
                           &result, 
                           &nRows,
                           &nCols, 
                           &zErr);
    if (rc != SQLITE_OK) {
        NSLog(@"sqlite3 query error: %s. \n sql:%@", zErr, sql);
        sqlite3_free(zErr);
        *t1 = 0;
        *t2 = 0;
        return -1;
    }
    startTime = *t1 = atol(result[2]);
    endTime = *t2 = atol(result[3]);
    sqlite3_free_table(result);
    
    hasGetStartEndTimes = YES;
    return startTime;
}

// 返回调度列表
// 结果存放在一个 NSMutableArray 中
// 每一项是一个表示CPUID为当前索引的CPU上的调度列表
// 其中，每一项是一个NSArray: [NSNumber *scheduleInTime, NSNumber *scheduleOutTime, NSString *pid]
- (NSMutableArray *)getScheduleList
{
    static NSMutableArray *scheduleList = nil;
    if (hasGetSchedulerList) {
        return scheduleList;
    }
    
    scheduleList = [[NSMutableArray alloc] init];
    int cpuCount = [self getCPUCount];
    for (int cpuid = 0; cpuid < cpuCount; ++cpuid) {
        NSString *sql = [NSString stringWithFormat:@"select cpuid, ts, eventName, pid1 from traceEvents "
                         "where (eventName='schedule' or eventName='unschedule') and cpuid=%d "
                         "order by ts asc",
                         cpuid];
        int rc, nRows, nCols;
        char **result;
        char *zErr;
        rc = sqlite3_get_table(traceDb, 
                               [sql cStringUsingEncoding:NSASCIIStringEncoding], 
                               &result, 
                               &nRows, 
                               &nCols, 
                               &zErr);
        if (rc != SQLITE_OK) {
            NSLog(@"sqlite3 query error: %s. \n sql:%@", zErr, sql);
            sqlite3_free(zErr);
            return nil;
        }
                
        NSArray *scheduleInstance = nil;
        NSNumber *scheduleInTime = nil;
        NSNumber *scheduleOutTime = nil;
        NSString *pid = nil;
        NSMutableArray *schedulesOnThisCPU = [[NSMutableArray alloc] init];
        for (int i = 0; i < nRows; ++i) {
            char *eventName = result[(i+1)*nCols + 2];
            if (0 == strcmp(eventName, "schedule")) {
                scheduleInTime = [NSNumber numberWithLong:atol(result[(i+1)*nCols + 1])];
            } else if (0 == strcmp(eventName, "unschedule")) {
                scheduleOutTime = [NSNumber numberWithLong:atol(result[(i+1)*nCols + 1])];
                if (scheduleInTime) {
                    pid = [NSString stringWithCString:result[(i+1)*nCols + 3] encoding:NSASCIIStringEncoding];
                    scheduleInstance = [NSArray arrayWithObjects:scheduleInTime, 
                                        scheduleOutTime, 
                                        pid, 
                                        nil];
                    [schedulesOnThisCPU addObject:scheduleInstance];
                    scheduleInTime = nil;
                }
            }
        }
        [scheduleList addObject:schedulesOnThisCPU];
        sqlite3_free_table(result);
    }
    
    hasGetSchedulerList = YES;
    return scheduleList;
}

// 返回spawn事件的列表
// 每一项是一个NSArray: [NSNumber *cpuId, NSNumber *timeStep, NSString *pid]
- (NSMutableArray *)getSpawnEventList
{
    static NSMutableArray *spawnEventList = nil;
    if (hasGetSpawnEventList) {
        return spawnEventList;
    }
    
    spawnEventList = [[NSMutableArray alloc] init];
    NSString *sql = [NSString stringWithFormat:@"select cpuid, ts, eventName, pid1 from traceEvents "
                     "where eventName='spawn' "
                     "order by ts asc"];
    int rc, nRows, nCols;
    char **result;
    char *zErr;
    rc = sqlite3_get_table(traceDb, 
                           [sql UTF8String], 
                           &result, 
                           &nRows, 
                           &nCols, 
                           &zErr);
    if (rc != SQLITE_OK) {
        NSLog(@"sqlite3 query error: %s. \n sql:%@", zErr, sql);
        sqlite3_free(zErr);
        return nil;
    }
    for (int i = 0; i < nRows; ++i) {
        NSNumber *cpuId = [NSNumber numberWithInt:atoi(result[(i+1)*nCols + 0])];
        NSNumber *timeStamp = [NSNumber numberWithLong:atol(result[(i+1)*nCols + 1])];
        NSString *pid = [NSString stringWithUTF8String:result[(i+1)*nCols + 3]];
        NSArray *spawnEvent = [NSArray arrayWithObjects:cpuId, timeStamp, pid, nil];
        [spawnEventList addObject:spawnEvent];
    }
    
    sqlite3_free_table(result);
    
    hasGetSpawnEventList = YES;
    return spawnEventList;
}

- (NSMutableArray *) getCacheMissesEventListInTimeRange:(NSUInteger)t1 to:(NSUInteger)t2
{
    NSMutableArray *cacheMissesEventsList = [[NSMutableArray alloc] init];
    NSString *sql = [NSString stringWithFormat:@"select ts from traceEvents "
                     "where eventName='cache_miss_count' "
                     "and ts>=%lu and ts<=%lu "
                     "order by ts asc",
                     t1, t2];
    int rc, nRows, nCols;
    char **result;
    char *zErr;
    rc = sqlite3_get_table(traceDb, 
                           [sql UTF8String], 
                           &result, 
                           &nRows, 
                           &nCols, 
                           &zErr);
    if (rc != SQLITE_OK) {
        NSLog(@"sqlite3 query error: %s. \n sql:%@", zErr, sql);
        sqlite3_free(zErr);
        return nil;
    }
    for (int i = 0; i < nRows; ++i) {
        NSNumber *timeStamp = [NSNumber numberWithLong:atol(result[(i+1)*nCols + 0])];
        [cacheMissesEventsList addObject:timeStamp];
    }
    
    sqlite3_free_table(result);
    
    return cacheMissesEventsList;
}




























@end
