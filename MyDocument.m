//
//  MyDocument.m
//  Compress
//
//  Created by Grayson Hansard on 8/3/06.
//  Copyright From Concentrate Software 2006 . All rights reserved.
//

#import "MyDocument.h"

@interface MyDocument (PrivateMethods)
-(void)compressMultipleFilesWithName:(NSString *)name;
@end

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
		[self addObserver:self forKeyPath:@"files" options:nil context:nil];
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	if ([[self files] count]) [tabView selectTabViewItemAtIndex:1]; // Opened .compress file
}

//- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
- (NSData *)dataRepresentationOfType:(NSString *)aType
{
	return [NSArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:[self files], @"files", [CompressionPopUpButton titleOfSelectedItem], @"compression", nil]];
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
	NSDictionary *d = [NSUnarchiver unarchiveObjectWithData:data];
	if (![d isKindOfClass:[NSDictionary class]]) return NO;
	
	[self setFiles:[d objectForKey:@"files"]];
	[self setCompressionMethod:[d objectForKey:@"compression"]];
	
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	return [self dataRepresentationOfType:nil];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	BOOL b = [self loadDataRepresentation:data ofType:typeName];
	[self updateChangeCount:NSChangeCleared];
	return b;
}

#pragma mark -
#pragma mark IBActions

-(IBAction)cancel:(id)sender
{
	[self setFiles:[NSArray array]];
	[self updateChangeCount:NSChangeCleared];
}

-(IBAction)compress:(id)sender
{
	if ([[self files] count] == 1)
	{
		Compressor *c = [Compressor compressor];
		[c setDelegate:self];
		[c compressFileAtPath:[[self files] objectAtIndex:0]
                    operation:[CompressionPopUpButton titleOfSelectedItem]];
	}
	else
		[NSApp beginSheet:ArchiveNameWindow modalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction)reveal:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile:[[self files] objectAtIndex:[tableView selectedRow]] 
												 inFileViewerRootedAtPath:nil];
}

-(IBAction)delete:(id)sender
{
	NSMutableArray *files = [NSMutableArray arrayWithArray:[self files]];
	if (![files count]) return;
	if ([tableView selectedRow] == -1) return;

	NSIndexSet *set = [tableView selectedRowIndexes]; // I hate NSIndexSet
	unsigned int count = [set count];
	unsigned int idx[count];
	int i;
	[set getIndexes:idx maxCount:count inIndexRange:nil];
	
	for (i = count-1; i > -1; i--) [files removeObjectAtIndex:idx[i]];
	if ([files count] == 0) [self cancel:sender];
	else [self setFiles:files];	
}

-(IBAction)endArchiveNameSheet:(id)sender
{
	[NSApp endSheet:ArchiveNameWindow];
	[ArchiveNameWindow orderOut:sender];
	NSString *name = [NSString stringWithString:[ArchiveNameField stringValue]];
	if ([name length]) [self compressMultipleFilesWithName:name];
}

- (IBAction)saveDocument:(id)sender { [super saveDocument:sender]; }

#pragma mark -
#pragma mark Private Methods

-(void)ASCompress:(NSScriptCommand *)command
{
	if ([[self files] count] == 0) return;
	else if ([[self files] count] == 1)
	{
		[self compress:nil];
		return;
	}
	
	NSString *name = [[command evaluatedArguments] objectForKey:@"name"];
	if (!name) name = @"Copmress";
	[self compressMultipleFilesWithName:name];
}

-(void)compressMultipleFilesWithName:(NSString *)name
{
	Compressor *c = [Compressor compressor];
	[c setDelegate:self];
	
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:path]) [fm removeFileAtPath:path handler:nil];
	[fm createDirectoryAtPath:path attributes:nil];
	NSEnumerator *e = [[self files] objectEnumerator];
	NSString *p = nil;
	while (p = [e nextObject]) [fm copyPath:p toPath:[path stringByAppendingPathComponent:[p lastPathComponent]]
									handler:nil];
	[c compressFileAtPath:path operation:[CompressionPopUpButton titleOfSelectedItem]];
}

#pragma mark -
#pragma mark Getters/Setters

-(NSWindow *)window
{
	return [[[self windowControllers] objectAtIndex:0] window];
}

-(NSArray *)files
{
	return _files;
}

-(void)setFiles:(NSArray *)files
{
	if (files && _files != files)
	{
		[_files release];
		_files = [files copy];
		[self setCompressionMethods:nil]; // Updates compression methods
		[self updateChangeCount:NSChangeDone];
		
		[tabView selectTabViewItemAtIndex:[files count] > 0];
	}
}

- (NSString *)compressionMethod
{
	return _compressionMethod;
}

- (void)setCompressionMethod:(NSString *)aValue
{
	NSString *oldCompressionMethod = _compressionMethod;
	_compressionMethod = [aValue retain];
	[oldCompressionMethod release];
}

-(NSArray *)compressionMethods
{
	if (![[self files] count]) return nil;
	else if ([[self files] count] == 1) 
	{
		BOOL folder = NO;
		if ([[NSFileManager defaultManager] fileExistsAtPath:[[self files] objectAtIndex:0] isDirectory:&folder] 
			&& folder)
			return [Compressor compressionMethodsForFolders];
		return [Compressor compressionMethodsForFiles];
	}
	return [Compressor compressionMethodsForFolders];
}

-(void)setCompressionMethods:(NSArray *)methods
{
	// This does nothing.  It's just for key-value coding.
}

#pragma mark -
#pragma mark Delegate methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"files"]) [tableView reloadData];
}

-(void)view:(NSView *)view receivedDroppedFiles:(NSArray *)files
{
	if ([files count] == 1)
	{
		NSString *path = [files objectAtIndex:0];
		if ([[Compressor compressionFileTypes] containsObject:[path pathExtension]]) // Uncompress file
		{
			[[Compressor compressor] compressFileAtPath:path operation:nil];
			return;
		}
	}
	
	[self setFiles:files];
//	[tabView selectTabViewItemAtIndex:1];
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row 
	dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pb = [info draggingPasteboard];
	
	if ([[pb types] containsObject:NSFilenamesPboardType])
		[self setFiles:[[self files] arrayByAddingObjectsFromArray:[pb propertyListForType:NSFilenamesPboardType]]];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	return NSDragOperationCopy;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	char c = [[aTableColumn identifier] characterAtIndex:0];
	NSString *item = [[self files] objectAtIndex:rowIndex];
	if (c == 'i') return [[NSWorkspace sharedWorkspace] iconForFile:item];
	else if (c == 'n') return [item lastPathComponent];
	return nil;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView { return [[self files] count]; }

-(void)compressorWillBegin:(Compressor *)compressor
{
	[NSApp beginSheet:ProgressWindow modalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[ProgressIndicator startAnimation:self];
}

-(void)compressor:(Compressor *)compressor operationProgressedTo:(NSNumber *)percent
{
	[ProgressIndicator setDoubleValue:[percent doubleValue]];
}

-(void)compressor:(Compressor *)compressor sentMessage:(NSString *)message
{
	[ProgressStatusText setStringValue:message];
}

-(void)compressorDidEnd:(Compressor *)compressor archivePath:(NSString *)path
{
	[NSApp endSheet:ProgressWindow];
	[ProgressIndicator stopAnimation:self];
	[ProgressWindow orderOut:self];
	
	if ([[self files] count] > 1)
	{
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm movePath:path toPath:[[@"~/Desktop/" stringByStandardizingPath] stringByAppendingPathComponent:[path lastPathComponent]] handler:nil];
		
		unsigned int failsafe = 20;
		while ([path pathExtension] && ![[path pathExtension] isEqualToString:@""])
		{
			path = [path stringByDeletingPathExtension];
			if (failsafe-- == 0) break;
		}
		[fm removeFileAtPath:path handler:nil];		
	}
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];
	if (action == @selector(delete:) && [[tableView selectedRowIndexes] count]) return YES;
		
	return NO;
}

@end
