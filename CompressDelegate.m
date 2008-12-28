//
//  CompressDelegate.m
//  Compress
//
//  Created by Grayson Hansard on 12/27/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import "CompressDelegate.h"

@implementation CompressDelegate

+ (void)load
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[[NSApplication sharedApplication] setDelegate:[[self class] new]];
	[pool release];
}

- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	return self;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	// NSLog(@"%s %@", _cmd, filename);
	NSString *ext = [filename pathExtension];
	if ([ext isEqualToString:@"compress"]) return NO;
	
	[[DecompressionWindowController sharedInstance] decompressFile:filename];
	return YES;
}

@end
