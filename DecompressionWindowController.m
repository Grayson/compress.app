//
//  DecompressionWindowController.m
//  Compress
//
//  Created by Grayson Hansard on 12/27/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import "DecompressionWindowController.h"


@implementation DecompressionWindowController

+ (id)sharedInstance
{
	static id instance = nil;
	if (!instance) instance = [[self class] new];
	return instance;
}

- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	[NSBundle loadNibNamed:@"Decompress" owner:self];
	
	return self;
}

- (void)awakeFromNib
{
}

- (void)decompressFile:(NSString *)path {
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return;
	[window makeKeyAndOrderFront:self];
	
	NSMutableArray *arr = [NSMutableArray arrayWithArray:self.filesToDecompress];
	[arr addObject:path];
	self.filesToDecompress = arr;
	
	if (_currentFilePath) return;
	Compressor *c = [Compressor compressor];
	[c setDelegate:self];
	[c decompressFileAtPath:path];
	self.currentFilePath = path;
}

-(void)compressorWillBegin:(Compressor *)compressor {
	// NSLog(@"%s", _cmd);
}

-(void)compressor:(Compressor *)compressor operationProgressedTo:(NSNumber *)percent {
	// NSLog(@"%s %@", _cmd, percent);
}

-(void)compressor:(Compressor *)compressor sentMessage:(NSString *)message {
	// NSLog(@"%s %@", _cmd, message);
}

-(void)compressorDidEnd:(Compressor *)compressor archivePath:(NSString *)path {
	// NSLog(@"%s", _cmd);
	NSMutableArray *arr = [NSMutableArray arrayWithArray:self.filesToDecompress];
	[arr removeObjectIdenticalTo:self.currentFilePath];
	self.currentFilePath = arr.pop;
	self.filesToDecompress = arr;
	if (self.currentFilePath) [compressor decompressFileAtPath:self.currentFilePath];
	else [window orderOut:self];
}

#pragma mark -
#pragma mark Getters/Accessors

- (NSString *)currentFilePath
{
	return _currentFilePath;
}

- (void)setCurrentFilePath:(NSString *)aValue
{
	NSString *oldCurrentFilePath = _currentFilePath;
	_currentFilePath = [aValue retain];
	[oldCurrentFilePath release];
}

- (NSArray *)filesToDecompress
{
	return _filesToDecompress;
}

- (void)setFilesToDecompress:(NSArray *)aValue
{
	NSArray *oldFilesToDecompress = _filesToDecompress;
	_filesToDecompress = [aValue retain];
	[oldFilesToDecompress release];
}

@end
