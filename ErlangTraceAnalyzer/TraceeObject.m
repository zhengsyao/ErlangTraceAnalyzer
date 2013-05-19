//
//  TraceeObject.m
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TraceeObject.h"

@interface TraceeObject ()
@property (nonatomic, strong) NSString *type;
@end

@implementation TraceeObject

@synthesize frame = _frame;
@synthesize type = _type;

@synthesize color = _color;
@synthesize selectedColor = _selectedColor;
@synthesize highlightedColor = _highlightedColor;

@synthesize selected = _selected;
@synthesize highlighted = _highlighted;
@synthesize hidden = _hidden;

- (id)initWithFrame:(NSRect)aRect 
              color:(NSColor *)aColor 
      selectedColor:(NSColor *)bColor
   highlightedColor:(NSColor *)cColor
{
    if (self = [super init]) {
        self.frame = aRect;
        self.color = [aColor copy];
        self.selectedColor = [bColor copy];
        self.highlightedColor = [cColor copy];
    }
    return self;
}

- (void)drawRect:(NSRect)aRect
{
    NSRect dRect;
    NSRectClip(aRect);
    dRect = NSIntersectionRect(aRect, self.frame);
    
    if (self.hidden) {
        [[NSColor clearColor] set];
        NSRectFill(dRect);
        return;
    }
    
    if (self.selected) {
        [self.selectedColor set];
    } else if (self.highlighted) {
        [self.highlightedColor set];
    } else {
        [self.color set];
    }
    NSRectFill(dRect);
}

- (NSString *)description
{
    return @"An event";
}














@end

