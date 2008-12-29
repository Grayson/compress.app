//
//  DecompressionWindowController.h
//  Compress
//
//  Created by Grayson Hansard on 12/27/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Compressor.h"
#import "NSMutableArray+FCSAdditions.h"


@interface DecompressionWindowController : NSObject {
	IBOutlet NSWindow *window;
	IBOutlet NSProgressIndicator *progressIndicator;
	NSString *_currentFilePath;
	NSArray *_filesToDecompress;
}

- (NSString *)currentFilePath;
- (void)setCurrentFilePath:(NSString *)aValue;

- (NSArray *)filesToDecompress;
- (void)setFilesToDecompress:(NSArray *)aValue;

+ (id)sharedInstance;
- (void)decompressFile:(NSString *)path;

- (IBAction)stop:(id)sender;

@end
