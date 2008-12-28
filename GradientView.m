//
//  GradientView.m
//  Compress
//
//  Created by Grayson Hansard on 12/28/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import "GradientView.h"
#import "NSBezierPath+FCSAdditions.h"

@implementation GradientView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	[[NSBezierPath bezierPathWithRect:self.bounds] fillGradientWithStartColor:[NSColor lightGrayColor]
                                                                     endColor:[NSColor grayColor]];
}

@end
