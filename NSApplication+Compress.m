//
//  NSApplication+Compress.m
//  Compress
//
//  Created by Grayson Hansard on 12/26/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import "NSApplication+Compress.h"


@implementation NSApplication (Compress)

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	NSLog(@"%s", _cmd);
	return NO;
}

@end
