//
//  PointEvent.m
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 6/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PointEvent.h"

@implementation PointEvent

@synthesize timeStamp = _timeStamp;

- (id)initWithFrame:(NSRect)aRect
{
    self = [super initWithFrame:aRect 
                          color:[NSColor knobColor] 
                  selectedColor:[NSColor redColor]
               highlightedColor:[NSColor blueColor]];
    return self;
}

- (void)drawRect:(NSRect)aRect
{
    NSRect dRect;
    NSRectClip(aRect);
    // 修改frame，中点不变
    NSRect newFrame = self.frame;
    newFrame.origin.x = self.frame.origin.x + self.frame.size.width/2 - 5;
    newFrame.size.width = 10;
    self.frame = newFrame;
    dRect = NSIntersectionRect(aRect, self.frame);
    
    if (self.hidden) {
        [[NSColor clearColor] set];
        NSRectFill(dRect);
        return;
    }
    
    if (self.selected) {
        [super.selectedColor set];
    } else if (self.highlighted) {
        [self.highlightedColor set];
    } else {
        [self.color set];
    }
    
    NSBezierPath *triangle = [[NSBezierPath alloc] init];
//    [triangle moveToPoint:NSMakePoint(self.frame.origin.x + self.frame.size.width/2, 
//                                      self.frame.origin.y + 10)];
//    [triangle lineToPoint:NSMakePoint(self.frame.origin.x + self.frame.size.width/2 + 5, 
//                                      self.frame.origin.y + 2)];
//    [triangle lineToPoint:NSMakePoint(self.frame.origin.x + self.frame.size.width/2 - 5, 
//                                      self.frame.origin.y + 2)];
    [triangle moveToPoint:NSMakePoint(self.frame.origin.x, self.frame.origin.y)];
    [triangle lineToPoint:NSMakePoint(self.frame.origin.x + self.frame.size.width, self.frame.origin.y)];
    [triangle lineToPoint:NSMakePoint(self.frame.origin.x + self.frame.size.width/2, 
                                      self.frame.origin.y + 8)];
    [triangle closePath];
    [triangle fill];
}

@end
