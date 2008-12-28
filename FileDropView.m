//
//  FileDropView.m
//  Countdown
//
//  Created by Grayson Hansard on 11/6/07.
//  Copyright 2007 From Concentrate Software. All rights reserved.
//

#import "FileDropView.h"


@implementation FileDropView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		// [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
		[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	NSColor *startColor = nil;
	NSColor *endColor = nil;
	if (self.inDrag) {
		startColor = [[NSColor selectedControlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		endColor = [startColor shadowWithLevel:0.3];
	}
	else {
		startColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
		endColor = [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
	}
	[[NSBezierPath bezierPathWithRect:[self bounds]] fillGradientWithStartColor:startColor endColor:endColor];
	
	if (_inDrag) [[NSColor whiteColor] set];
	else [[NSColor grayColor] set];
	
	NSRect bounds = self.bounds;
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(bounds, bounds.size.width * .1, bounds.size.height *.2)]; //RoundedRect:[self bounds] xRadius:5. yRadius:5.];
	float dash[2] = {10., 2.};
	[path setLineDash:dash count:2 phase:_phase];
	[path setLineWidth:5.];
	[path stroke];
	
	// if (self.inDrag) {
	// 	[[[NSColor selectedControlColor] shadowWithLevel:0.1] set];
	// 	[path fill];
	// }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	_animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(animate:) userInfo:nil repeats:YES];
	self.inDrag = YES;
	return [super draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	[_animationTimer invalidate];
	self.inDrag = NO;
	[self setNeedsDisplay:YES];
	return [super draggingExited:sender];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
	[_animationTimer invalidate];
	self.inDrag = NO;
	[self setNeedsDisplay:YES];
	return [super draggingEnded:sender];
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender {
	[_animationTimer invalidate];
	self.inDrag = NO;
	[self setNeedsDisplay:YES];
}

- (void)animate:(NSTimer *)aTimer
{
	_phase = (_phase + 1) % 12;
	[self setNeedsDisplay:YES];
}

- (BOOL)inDrag { return _inDrag; }
- (void)setInDrag:(BOOL)newInDrag {
	_inDrag = newInDrag;
	[self setNeedsDisplay:YES];
	[textField setTextColor:(_inDrag ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.3 alpha:1.])];
}


@end
