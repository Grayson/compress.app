//
//  FileDropView.h
//  Countdown
//
//  Created by Grayson Hansard on 11/6/07.
//  Copyright 2007 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DropView.h"
#import "NSApplication+FCSAdditions.h"
#import "NSBezierPath+FCSAdditions.h"

@interface FileDropView : DropView {
	int _phase;
	NSTimer *_animationTimer;
	BOOL _inDrag;
	IBOutlet NSTextField *textField;
}

- (BOOL)inDrag;
- (void)setInDrag:(BOOL)newInDrag;

@end
