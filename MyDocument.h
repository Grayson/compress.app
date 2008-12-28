//
//  MyDocument.h
//  Compress
//
//  Created by Grayson Hansard on 8/3/06.
//  Copyright From Concentrate Software 2006 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "Compressor.h"

@interface MyDocument : NSDocument
{
	IBOutlet NSTabView *tabView;
	IBOutlet NSTableView *tableView;
	IBOutlet NSWindow *ArchiveNameWindow, *ProgressWindow;
	IBOutlet NSProgressIndicator *ProgressIndicator;
	IBOutlet NSTextField *ProgressStatusText, *ArchiveNameField;
	IBOutlet NSPopUpButton *CompressionPopUpButton;
	NSArray *_files;
	NSString *_compressionMethod;
}

-(IBAction)cancel:(id)sender;
-(IBAction)compress:(id)sender;
-(IBAction)reveal:(id)sender;
-(IBAction)delete:(id)sender;

-(NSWindow *)window;

-(NSArray *)files;
-(void)setFiles:(NSArray *)files;

-(NSString *)compressionMethod;
-(void)setCompressionMethod:(NSString *)method;

-(NSArray *)compressionMethods;
-(void)setCompressionMethods:(NSArray *)methods;

@end
