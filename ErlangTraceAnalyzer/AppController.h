//
//  AppController.h
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "TraceView.h"
#import "TraceDataSourceProtocol.h"

@interface AppController : NSObject <TraceDataSourceProtocol>

@property (strong) IBOutlet TraceView *traceView;
@property (strong) IBOutlet NSTextField *selectedItemDescription;
@property (strong) IBOutlet NSButton *savePDFButton;

- (IBAction)loadPressed:(NSButton *)sender;
- (IBAction)zoomInPressed:(NSButton *)sender;
- (IBAction)zoomOutPressed:(NSButton *)sender;
- (IBAction)highRelatedEventsPressed:(NSButton *)sender;
- (IBAction)savePDFPressed:(NSButton *)sender;

@end
