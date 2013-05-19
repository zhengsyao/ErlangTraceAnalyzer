//
//  TraceView.m
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TraceView.h"
#import "ErlangProcess.h"
#import "SpawnEvent.h"

@implementation TraceView {
    // 字体相关
    NSFont *textFont;
    NSDictionary *textAttrsDictionary;
    
    // 绘制tick相关
    CGFloat intervalPerTick;    // 每两个tick之间表示的采样时间间隔，随着scale变化而变化
    CGFloat tickWidth;  // 每两个tick之间的距离
    
    // 选择相关
    TraceeObject *oldSelectedTracee;
}

@synthesize tracees = _tracees;
@synthesize dataSource = _dataSource;

- (NSMutableArray *)tracees
{
    if (!_tracees) {
        _tracees = [[NSMutableArray alloc] init];
    }
    return _tracees;
}

+ (void)initialize
{
    static BOOL isInitialized = NO;
    
    if (isInitialized) return;
    isInitialized = YES;
}

- (void)reset
{
    // 设置字体
    textFont = [NSFont fontWithName:@"Helvetica" size:12.0];
    textAttrsDictionary =[NSDictionary dictionaryWithObject:textFont forKey:NSFontAttributeName];
    // 设置tick绘制相关的参数
    intervalPerTick = 10000;
    tickWidth = 80;
    
    oldSelectedTracee = nil;
    [self.tracees removeAllObjects];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self reset];
    }
        
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSEnumerator *numer;
    TraceeObject *aTracee;
    
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
    
    [self drawBackground:dirtyRect];
    
    // 绘制从30个点之后进行
    NSRect drawRect = dirtyRect;
    drawRect.origin.x += LEADINGWHITEPOINTS;
    drawRect.size.width -= LEADINGWHITEPOINTS;
    
    numer = [self.tracees objectEnumerator];
    while ((aTracee = [numer nextObject])) {
        if (NSIntersectsRect([aTracee frame], drawRect)) {
            [aTracee drawRect:drawRect];
        }
    }
}

- (NSString *)currentSelectionDescription
{
    if (oldSelectedTracee) {
        return [oldSelectedTracee description];
    } else {
        return @"No selection";
    }
}

- (void)setCurrentSelectionDescription:(NSString *)currentSelectionDescription
{
    // do nothing
    return;
}

- (void)drawBackground:(NSRect)dirtyRect
{
    // 画左侧的CPU列表
    NSColor *colorStrip1 = [NSColor colorWithDeviceWhite:0.9 alpha:1.0];
    NSColor *colorStrip2 = [NSColor whiteColor];
    NSArray *interleavedColors = [NSArray arrayWithObjects:colorStrip1, colorStrip2, nil];
    int numCPU = [self.dataSource getCPUCount];
    if (numCPU <= 0) {
        numCPU = 0;
    }
    NSRect numberBox;
    for (int i = 0; i < numCPU; ++i) {
        NSColor *curColor = [interleavedColors objectAtIndex:i%2];
        [curColor set];
        NSRectFill(NSMakeRect(dirtyRect.origin.x, (i + 1) * 30, dirtyRect.size.width, 30));
        numberBox = NSMakeRect(dirtyRect.origin.x + 5, (i + 1) * 30 + 10, 30, 30);
        NSString *cpuId = [[NSString alloc] initWithFormat:@"%d", i];
        [cpuId drawInRect:numberBox withAttributes:textAttrsDictionary];
    }
    
    // 画cache_misses事件
    NSRect cacheLabelBox = NSMakeRect(dirtyRect.origin.x + 5, (numCPU + 1) * 30 + 10, 30, 30);
    [@"C" drawInRect:cacheLabelBox withAttributes:textAttrsDictionary];
    // 计算当前框内的时间范围
    NSUInteger traceStartTime, traceEndTime;
    [self.dataSource getStartTime:&traceStartTime endTime:&traceEndTime];
    NSUInteger startTimeInView, endTimeInView;
    if (dirtyRect.origin.x >= LEADINGWHITEPOINTS){
        startTimeInView = (dirtyRect.origin.x - LEADINGWHITEPOINTS) / tickWidth * intervalPerTick + traceStartTime;
    } else {
        startTimeInView = 0 + traceStartTime;
    }
    endTimeInView = (dirtyRect.origin.x + dirtyRect.size.width - LEADINGWHITEPOINTS) / tickWidth * intervalPerTick + traceStartTime;
    NSMutableArray *cacheMissesEvents = [self.dataSource getCacheMissesEventListInTimeRange:startTimeInView to:endTimeInView];
    [[NSColor blackColor] set];
    for (NSNumber *timeStamp in cacheMissesEvents) {
        NSUInteger ts = [timeStamp longValue];
        CGFloat xPos = (ts - traceStartTime) / intervalPerTick * tickWidth + LEADINGWHITEPOINTS;
        [NSBezierPath strokeLineFromPoint:NSMakePoint(xPos, (numCPU + 1) * 30 + 10) toPoint:NSMakePoint(xPos, (numCPU + 1) * 30 + 10 + 10)];
    }
    
    
    // 画时间轴
    NSUInteger firstIndex;
    if (dirtyRect.origin.x >= LEADINGWHITEPOINTS){
        firstIndex = (NSUInteger)(dirtyRect.origin.x - LEADINGWHITEPOINTS) / (NSUInteger)tickWidth;
    } else {
        firstIndex = 0;
    }
    CGFloat firstX = LEADINGWHITEPOINTS + tickWidth * firstIndex;
    CGFloat x;
    NSUInteger index;
    for (x = firstX, index = firstIndex; 
         x <= dirtyRect.size.width + dirtyRect.origin.x; 
         x += tickWidth, ++index) {
        numberBox = NSMakeRect(x, 15, 100, 15);
        NSString *timeTick = [[NSString alloc] initWithFormat:@"%.0f", index*intervalPerTick];
        [timeTick drawInRect:numberBox withAttributes:textAttrsDictionary];
        [[NSColor blackColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, 30) toPoint:NSMakePoint(x, dirtyRect.origin.y+30*(numCPU+1))];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    TraceeObject *selectedItem = nil;
    for (TraceeObject *tracee in self.tracees) {
        if ([self mouse:mouseLoc inRect:tracee.frame]) {
            selectedItem = tracee;
            break;
        }
    }
    
    if (selectedItem) {
        if (selectedItem == oldSelectedTracee) {
            return;
        } else {
            // 选择了新的项目
            selectedItem.selected = YES;
        }
    } 
    if (oldSelectedTracee) {
        oldSelectedTracee.selected = NO;
    }
    
    oldSelectedTracee = selectedItem;
    self.currentSelectionDescription = nil; // 触发绑定的修改
    
    [self setNeedsDisplay:YES];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    
}

- (void)zoom:(TraceViewZoomType)zoomType
{
    CGFloat zoomFactor;
    if (zoomType == traceViewZoomIn) {
        zoomFactor = ZOOMINFACTOR;
    } else if (zoomType == traceViewZoomOut) {
        zoomFactor = ZOOMOUTFACTOR;
    } else {
        return;
    }
    
    // 计算当前frame所在的比例
    // NSRect traceViewFrame = [self frame];
    NSRect traceViewVisibleFrame = [[self enclosingScrollView] documentVisibleRect];
    // double currentPosition = (traceViewVisibleFrame.origin.x) / (traceViewFrame.size.width - LEADINGWHITEPOINTS);
    double currentPosition = [[[self enclosingScrollView] horizontalScroller] doubleValue];
    // NSLog(@"traceViewVisibleFrame x=%f y=%g w=%g h=%g", traceViewVisibleFrame.origin.x, traceViewVisibleFrame.origin.y, traceViewVisibleFrame.size.width, traceViewVisibleFrame.size.height);
    // NSLog(@"current knob position %f", currentPosition);
    
    // 进行缩放操作
    NSRect newTraceViewFrame = [self frame];
    newTraceViewFrame.size.width = (NSWidth(newTraceViewFrame) - LEADINGWHITEPOINTS) * zoomFactor + LEADINGWHITEPOINTS;
    [self setFrame:newTraceViewFrame];
    
    for (TraceeObject *thisTracee in self.tracees) {
        NSRect newObjectFrame = thisTracee.frame;
        newObjectFrame.origin.x = (thisTracee.frame.origin.x - LEADINGWHITEPOINTS) * zoomFactor + LEADINGWHITEPOINTS;
        newObjectFrame.size.width = NSWidth(thisTracee.frame) * zoomFactor;
        thisTracee.frame = newObjectFrame;
    }
    
    intervalPerTick /= zoomFactor;
    
    // 恢复zoom之前所在的比例
    if (newTraceViewFrame.size.width < traceViewVisibleFrame.size.width) {
        currentPosition = 0.0;
    }
    CGFloat newX = (newTraceViewFrame.size.width) * currentPosition;
    [[[self enclosingScrollView] horizontalScroller] setDoubleValue:currentPosition];
    [[[self enclosingScrollView] contentView] scrollToPoint:NSMakePoint(newX, traceViewVisibleFrame.origin.y)];
    
    // 通知重绘
    NSScrollView *scrollView = [self enclosingScrollView];
    if (scrollView) {
        [scrollView setNeedsDisplay:YES];
    } else {
        [[self superview] setNeedsDisplay:YES];
    }
}

- (void)loadNewData
{
    int cpuCount;
    NSUInteger traceStartTime, traceEndTime;
    
    [self reset];
    
    // 设置view的边框
    cpuCount = [self.dataSource getCPUCount];
    [self.dataSource getStartTime:&traceStartTime endTime:&traceEndTime];
    CGFloat viewHeight = (cpuCount + 2) * 30;
    CGFloat viewWidth = ((traceEndTime - traceStartTime) / intervalPerTick + 1) * tickWidth + LEADINGWHITEPOINTS;
    
    [self setFrame:NSMakeRect(0.0, 0.0, viewWidth, viewHeight)];
    
    // 加载数据
    // 调度
    NSMutableArray *scheduleList = [self.dataSource getScheduleList];
    ErlangProcess *aProcess;
    NSMutableDictionary *erlangProcessColorDictionary = [[NSMutableDictionary alloc] init];
    NSColor *erlangProcessColor;
    for (int cpuid = 0; cpuid < cpuCount; ++cpuid) {
        for (NSArray *aSchedule in [scheduleList objectAtIndex:cpuid]) {
            NSUInteger scheduleInTime = [[aSchedule objectAtIndex:0] longValue];
            NSUInteger scheduleOutTime = [[aSchedule objectAtIndex:1] longValue];
            NSString *pid = [aSchedule objectAtIndex:2];
            NSRect aRect = NSMakeRect((scheduleInTime - traceStartTime)/intervalPerTick*tickWidth + LEADINGWHITEPOINTS, 
                                      (cpuid + 1)*30+10, 
                                      (scheduleOutTime - scheduleInTime)/intervalPerTick*tickWidth, 
                                      15);
            aProcess = [[ErlangProcess alloc] initWithFrame:aRect];
            aProcess.startTime = scheduleInTime - traceStartTime;
            aProcess.endTime = scheduleOutTime - traceStartTime;
            aProcess.pid = pid;
            // 设置颜色
            if ((erlangProcessColor = [erlangProcessColorDictionary objectForKey:pid])) {
            } else {
                erlangProcessColor = [NSColor colorWithDeviceRed:(CGFloat)rand()/RAND_MAX 
                                                           green:(CGFloat)rand()/RAND_MAX 
                                                            blue:(CGFloat)rand()/RAND_MAX 
                                                           alpha:1.0];
                [erlangProcessColorDictionary setObject:erlangProcessColor forKey:pid];
            }
            aProcess.color = erlangProcessColor;
            [self.tracees addObject:aProcess];
        }
    }
    
    // spawn event
    NSMutableArray *spawnEventList = [self.dataSource getSpawnEventList];
    SpawnEvent *aSpawnEvent;
    for (NSArray *aSpawnEventArray in spawnEventList) {
        int cpuId = [[aSpawnEventArray objectAtIndex:0] intValue];
        NSUInteger timeStamp = [[aSpawnEventArray objectAtIndex:1] longValue];
        NSString *pid = [aSpawnEventArray objectAtIndex:2];
        NSRect aRect = NSMakeRect((timeStamp - traceStartTime)/intervalPerTick*tickWidth + LEADINGWHITEPOINTS - 10,
                                  (cpuId + 1)*30, 
                                  20, 
                                  10);
        aSpawnEvent = [[SpawnEvent alloc] initWithFrame:aRect];
        aSpawnEvent.pid = pid;
        aSpawnEvent.timeStamp = timeStamp - traceStartTime;
        [self.tracees addObject:aSpawnEvent];
    }
    
    [self setNeedsDisplay:YES];
    
}

- (void)highlightEventsAccordingToCurrentSelected
{
    if (oldSelectedTracee) {
        if ([oldSelectedTracee respondsToSelector:@selector(pid)]) {
            NSString *pid = [oldSelectedTracee performSelector:@selector(pid)];
            [self highlightEventsWithPid:pid];
        }
    }
}

- (void)highlightEventsWithPid:(NSString *)pid
{
    for (TraceeObject *tracee in self.tracees) {
        if ([tracee respondsToSelector:@selector(pid)]) {
            if ([[tracee performSelector:@selector(pid)] isEqualTo:pid]) {
                tracee.highlighted = YES;
            } else {
                tracee.highlighted = NO;
            }
        }
    }
}



























@end
