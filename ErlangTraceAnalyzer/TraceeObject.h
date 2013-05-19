//
//  TraceeObject.h
//  ErlangTraceAnalyzer
//
//  Created by Zheng Siyao on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TraceeObject : NSObject

@property (nonatomic) NSRect frame;
@property BOOL selected;
@property BOOL highlighted;
@property BOOL hidden;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic, strong) NSColor *selectedColor;
@property (nonatomic, strong) NSColor *highlightedColor;

- (id)initWithFrame:(NSRect)aRect 
              color:(NSColor *)aColor 
      selectedColor:(NSColor *)bColor 
   highlightedColor:(NSColor *)cColor; 
- (void)drawRect:(NSRect)aRect;

@end
