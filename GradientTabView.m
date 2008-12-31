#import "GradientTabView.h"
#import "NSBezierPath+FCSAdditions.h"

@implementation GradientTabView

-(void)drawRect:(NSRect)rect
{
	[[NSBezierPath bezierPathWithRect:[self bounds]] fillGradientWithStartColor:[NSColor colorWithCalibratedWhite:0.85 alpha:1.]
                                                                       endColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.]];
	[super drawRect:rect];
}

@end
