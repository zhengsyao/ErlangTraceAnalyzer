//
//  TraceView.h
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TraceDataSourceProtocol.h"

#define LEADINGWHITEPOINTS (30.0)

#define ZOOMINFACTOR   (2.0)
#define ZOOMOUTFACTOR  (1.0 / ZOOMINFACTOR)

typedef enum _TraceViewZoomType {
    traceViewZoomIn = 0,
    traceViewZoomOut = 1
} TraceViewZoomType;

@interface TraceView : NSView

@property (nonatomic, strong) NSMutableArray *tracees;
@property (nonatomic, strong) id <TraceDataSourceProtocol> dataSource;

@property (strong) NSString *currentSelectionDescription;

- (void)zoom:(TraceViewZoomType)zoomType;
- (void)loadNewData;
- (void)highlightEventsWithPid:(NSString *)pid;
- (void)highlightEventsAccordingToCurrentSelected;

@end
