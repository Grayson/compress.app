//
//  Compressor.m
//  Compress
//
//  Created by Grayson Hansard on 8/3/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
//

#import "Compressor.h"

// 32kb buffer
#define BUFFER_SIZE (32*1024)

@interface Compressor (PrivateMethods)
-(void)sendMessage:(NSString *)msg;
-(void)postProgress:(NSNumber *)progress;
@end

@implementation Compressor

+(NSArray *)compressionMethodsForFiles
{
	return [NSArray arrayWithObjects:@"bzip2", @"gzip", @"dmg", @"dmg & bzip2", @"dmg & gzip", @"dmg & zip", @"dmg & p7zip", @"p7zip", @"zip", nil];
}

+(NSArray *)compressionMethodsForFolders
{
	return [NSArray arrayWithObjects: @"tar", @"tar & bzip2", @"tar & gzip", @"tar & zip", @"tar & p7zip", @"dmg", @"dmg & bzip2", @"tar & gzip", @"tar & zip", @"tar & p7zip", @"p7zip", @"zip", nil];;
}

+(NSArray *)compressionFileTypes { return [NSArray arrayWithObjects:@"tar", @"gz", @"bz2", @"7z", @"dmg", @"zip", nil]; }

+(id)compressor
{
	return [[[self class] new] autorelease];
}

-(void)compressFileAtPath:(NSString *)path operation:(NSString *)op
{
	[NSThread detachNewThreadSelector:@selector(_threadedCompressFile:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"path", op, @"operation", nil]];
}

- (void)decompressFileAtPath:(NSString *)path {
	[NSThread detachNewThreadSelector:@selector(_threadedDecompressFileAtPath:) toTarget:self withObject:path];
}

- (void)_threadedDecompressFileAtPath:(NSString *)path {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	if ([self delegate] && [[self delegate] respondsToSelector:@selector(compressorWillBegin:)])
		[[self delegate] compressorWillBegin:self];
	
	path = [NSString stringWithString:path];
	
	while (true) {
		NSString *ext = [path pathExtension];
		SEL selector = nil;
		if ([ext isEqualToString:@"tar"]) selector = @selector(untar:);
		else if ([ext isEqualToString:@"gz"]) selector = @selector(gunzip:);
		else if ([ext isEqualToString:@"zip"]) selector = @selector(unzip:);
		else if ([ext isEqualToString:@"bz2"]) selector = @selector(bunzip2:);
		else if ([ext isEqualToString:@"7z"] || [ext isEqualToString:@"cb7"]) selector = @selector(unp7zip:);
		else break;
		
		[self performSelector:selector withObject:path];
		path = [path stringByDeletingPathExtension];
	}
	
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(compressorDidEnd:archivePath:)])
		[[self delegate] compressorDidEnd:self archivePath:path];
	
	[pool release];
}

-(void)_threadedCompressFile:(NSDictionary *)args
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSString *path = [args objectForKey:@"path"];
	NSString *op = [args objectForKey:@"operation"];
	
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(compressorWillBegin:)])
		[[self delegate] compressorWillBegin:self];
	
	NSString *ext = [path pathExtension];
	NSMutableString *ss = [NSMutableString stringWithString:path];
	NSArray *operations = [op componentsSeparatedByString:@" "];
	NSEnumerator *e = [operations objectEnumerator];
	NSString *s = nil;
	
	if ([ext isEqualToString:@"tar"] || [ext isEqualToString:@"gz"] || [ext isEqualToString:@"bz2"]
		|| [ext isEqualToString:@"zip"] || [ext isEqualToString:@"7z"] || [ext isEqualToString:@"dmg"]) //uncompress
	{
		while (![ext isEqualToString:@""])
		{
			if ([ext isEqualToString:@"tar"])
				[self untar:path];
			else if ([ext isEqualToString:@"gz"])
				[self gunzip:path];
			else if ([ext isEqualToString:@"bz2"])
				[self bunzip2:path];
			else if ([ext isEqualToString:@"zip"])
				[self unzip:path];
			else if ([ext isEqualToString:@"7z"])
				[self unp7zip:path];
			else if ([ext isEqualToString:@"dmg"])
				[self undmg:path];
			
			path = [path stringByDeletingPathExtension];
			ext = [path pathExtension];
		}
		[ss setString:path];
	}
	else //compress
	{
		while (s = [e nextObject])
		{
			if ([s isEqualToString:@"tar"])
			{
				[self tar:ss];
				[ss appendString:@".tar"];
			}
			else if ([s isEqualToString:@"gzip"])
			{
				[self gzip:ss];
				[ss appendString:@".gz"];
			}
			else if ([s isEqualToString:@"bzip2"])
			{
				[self bzip2:ss];
				[ss appendString:@".bz2"];
			}
			else if ([s isEqualToString:@"zip"])
			{
				[self zip:ss];
				[ss appendString:@".zip"];
			}
			else if ([s isEqualToString:@"p7zip"])
			{
				[self p7zip:ss];
				[ss appendString:@".7z"];
			}
			else if ([s isEqualToString:@"dmg"])
			{
				[self dmg:ss];
				[ss appendString:@".dmg"];
			}
		}
	}
	
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(compressorDidEnd:archivePath:)])
		[[self delegate] compressorDidEnd:self archivePath:ss];
	
	[pool release];
	
//	return ss;
}

-(id)delegate { return _delegate; }
-(void)setDelegate:(id)delegate { _delegate = delegate; }

-(void)tar:(NSString *)path
{
	[[NSFileManager defaultManager] changeCurrentDirectoryPath:[path stringByDeletingLastPathComponent]];
	NSTask *tar = [NSTask new];
	[tar setLaunchPath:@"/usr/bin/tar"];
	
	[tar setArguments:[NSArray arrayWithObjects:@"-C", path, 
		@"-cf", [NSString stringWithFormat:@"%@.tar", [path lastPathComponent]], @".", nil]];
	[tar launch];
	[tar waitUntilExit];
	[tar release];
}

-(void)untar:(NSString *)path
{
	NSData *d = [NSData dataWithContentsOfFile:path];
	unsigned int fileSize = [d length];

	unsigned int count = 0;
	FILE *archive = fopen([path fileSystemRepresentation], "r");
	if (archive)
	{
		NSString *parentFolderPath = [path stringByDeletingLastPathComponent];
		NSString *fileName = [[path lastPathComponent] stringByDeletingPathExtension];
		NSString *destDir = [NSString stringWithFormat:@"%@/%@", parentFolderPath, fileName];
		
		NSFileManager *fm = [NSFileManager defaultManager];
		unsigned int idx = 0;
		while ([fm fileExistsAtPath:destDir])
			destDir = [NSString stringWithFormat:@"%@/%@ %i", parentFolderPath, fileName, ++idx];
		[fm createDirectoryAtPath:destDir attributes:nil];
		
		NSString *tarStuff = [NSString stringWithFormat:@"tar -C \"%@\" -x", destDir];
		FILE *tar = popen([tarStuff fileSystemRepresentation], "w");
		if (tar)
		{
			unsigned int buffer[BUFFER_SIZE];
			size_t len;
			while (len = fread(buffer, 1, (BUFFER_SIZE), archive))
			{
				count += len;
				[self postProgress:[NSNumber numberWithFloat:count/fileSize*100.]];
				fwrite(buffer, 1, len, tar);
			}
		}
		
		pclose(tar);
	}
	fclose(archive);
}

-(void)gzip:(NSString *)path
{
	int fileDescriptor = open([path fileSystemRepresentation], O_RDONLY);
	if (fileDescriptor == -1)
		return;
	
	[self sendMessage:NSLocalizedString(@"gzipping\\U2026", @"msg")];
	long long fileSize = lseek(fileDescriptor, 0, SEEK_END);
	
	lseek(fileDescriptor, 0, SEEK_SET);
	
	gzFile gzippedFile = gzopen([[path stringByAppendingPathExtension:@"gz"] fileSystemRepresentation], "w");
	if (!gzippedFile) 
		return;
	
	unsigned char buffer[BUFFER_SIZE];
	int readSize = 0;
	long count = 0;
	readSize = read(fileDescriptor, &buffer, BUFFER_SIZE);
	while (readSize != 0)
	{
		gzwrite(gzippedFile, buffer, readSize);
		count += readSize;
		[self postProgress:[NSNumber numberWithFloat:count/fileSize*100.]];
		readSize = read(fileDescriptor, &buffer, BUFFER_SIZE);
	}
	
	gzclose(gzippedFile);
	close(fileDescriptor);
}

-(void)gunzip:(NSString *)path
{	
	gzFile gzippedFile = gzopen([path fileSystemRepresentation], "r");
	if (!gzippedFile)
		return;
	int fileDescriptor = open([[path stringByDeletingPathExtension] fileSystemRepresentation], 
							  O_WRONLY | O_CREAT | O_EXCL);
	if (fileDescriptor == -1)
		return;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary *fileDict = [fm fileAttributesAtPath:path traverseLink:YES];
	long long fileSize = 0;
	
	if (fileDict)
	{
		NSNumber *fileSizeAttr = [fileDict objectForKey:NSFileSize];
		if (fileSizeAttr) fileSize = [fileSizeAttr longLongValue];
	}
	
	gzseek(gzippedFile, 0, SEEK_SET);
	
	unsigned char buffer[BUFFER_SIZE];
	int readSize = 0;
	long long count = 0;
	readSize = gzread(gzippedFile, &buffer, BUFFER_SIZE);
	while (readSize != 0)
	{
		write(fileDescriptor, buffer, readSize);
		count += readSize;
		[self postProgress:[NSNumber numberWithFloat:count/fileSize*100.]];
		readSize = gzread(gzippedFile, &buffer, BUFFER_SIZE);
	}
}

-(void)bzip2:(NSString *)path
{
	int fileDescriptor = open([path fileSystemRepresentation], O_RDONLY);
	if (fileDescriptor == -1)
		return;
	
	int err = 0;
	FILE *f = fopen([[path stringByAppendingPathExtension:@"bz2"] fileSystemRepresentation], "w+");
	if (!f)
		return;
	
	BZFILE *bzippedFile = BZ2_bzWriteOpen(&err, f, 9, 0, 30);
	if (err != BZ_OK)
		goto cleanup;
	
	long long fileSize = lseek(fileDescriptor, 0, SEEK_END);
	lseek(fileDescriptor, 0, SEEK_SET); // Reset read cursor
	
	unsigned char buffer[BUFFER_SIZE];
	long readSize = 0;
	long long count = 0;
	
	readSize = read(fileDescriptor, buffer, BUFFER_SIZE);
	while (readSize != 0)
	{
		BZ2_bzWrite(&err, bzippedFile, buffer, readSize);
		if (err != BZ_OK)
			goto cleanup;
		
		count += readSize;
		[self postProgress:[NSNumber numberWithFloat:count/fileSize*100.]];
		readSize = read(fileDescriptor, buffer, BUFFER_SIZE);
	}
	
cleanup:;
	if (bzippedFile) BZ2_bzWriteClose(&err, bzippedFile, nil, nil, nil);
	if (f) fclose(f);
	if (fileDescriptor != -1) close(fileDescriptor);
}

-(void)bunzip2:(NSString *)path
{
	int err = 0;
	FILE *f = fopen([path fileSystemRepresentation], "r");
	if (!f)
		return;
	
	BZFILE *bzippedFile = BZ2_bzReadOpen(&err, f, 0, 0, nil, 0);
	if (err != BZ_OK)
		goto cleanup;
	
	int fileDescriptor = open([[path stringByDeletingPathExtension] fileSystemRepresentation], 
							  O_WRONLY | O_CREAT | O_EXCL);
	if (fileDescriptor == -1)
		goto cleanup;
	
	if (fseek(f, 0, SEEK_END) != 0)
		goto cleanup;
	
	long long fileSize = ftell(f);
	if (fseek(f, 0, SEEK_SET) != 0)
		goto cleanup;
	
	unsigned char buffer[BUFFER_SIZE];
	long readSize = 0;
	long long count = 0;
	
	readSize = BZ2_bzRead(&err, bzippedFile, buffer, BUFFER_SIZE);
	while (YES)
	{
		if (err != BZ_OK && err != BZ_STREAM_END)
			goto cleanup;

		write(fileDescriptor, buffer, readSize);
		count += readSize;
		[self postProgress:[NSNumber numberWithFloat:count/fileSize*100.]];
		
		if (err == BZ_STREAM_END) break; // If read everything, break loop
		count = BZ2_bzRead(&err, bzippedFile, buffer, BUFFER_SIZE);
	}
	
cleanup:;
	if (bzippedFile) BZ2_bzReadClose(&err, bzippedFile);
	if (f) fclose(f);
	if (fileDescriptor != -1) close(fileDescriptor);
}

-(void)p7zip:(NSString *)path
{
	NSString *pathTo7za = [[NSBundle mainBundle] pathForResource:@"7za" ofType:@""];
	NSString *outPath = [path stringByAppendingPathExtension:@"7z"];
	NSString *args = @"a";
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSString *comp = [ud objectForKey:@"7zipCompression"];
	if (comp && ![comp isEqualToString:@""])
		args = [NSString stringWithFormat:@"a %@", comp, nil];
	
	BOOL folder = NO;
	// Punt if it's a folder
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&folder] && folder)
	{
		NSArray *trueArgs = [args componentsSeparatedByString:@" "];
		NSMutableArray *arguments = [NSMutableArray arrayWithArray:trueArgs];
		[arguments addObject:outPath];
		[arguments addObject:path];
		
		NSTask *t = [NSTask new];
		t.launchPath = pathTo7za;
		t.arguments = arguments;
		
		[t launch];
		[t release];		
	}
	
	// Do file stuff
	unsigned long long count = 0;
	FILE *archive = fopen([path fileSystemRepresentation], "r");
	if (archive)
	{
		args = [NSString stringWithFormat:@"%@ -si", args, nil];
		fseek(archive, 0, SEEK_END);
		unsigned long long fileSize = ftell(archive);
		fseek(archive, 0, SEEK_SET);
		NSString *p7zipStr = [NSString stringWithFormat:@"'%@' %@ '%@'", pathTo7za, args, outPath];
		FILE *p7zip = popen([p7zipStr fileSystemRepresentation], "w");
		if (p7zip)
		{
			unsigned char buffer[BUFFER_SIZE];
			size_t len;
			while (len = fread(buffer, 1, BUFFER_SIZE, archive))
			{
				count+=len;
				[self postProgress:[NSNumber numberWithFloat:count/fileSize*100.]];
				fwrite(buffer, 1, len, p7zip);
			}
		}
		pclose(p7zip);
	}
	fclose(archive);
}

-(void)unp7zip:(NSString *)path
{
	NSString *pathTo7za = [[NSBundle mainBundle] pathForResource:@"7za" ofType:@""];
	NSString *outPath = [path stringByDeletingLastPathComponent];
	NSString *unp7zip = [NSString stringWithFormat:@"'%@' x '%@' -o'%@'", pathTo7za, path, outPath];
	system([unp7zip fileSystemRepresentation]);
}

-(void)dmg:(NSString *)path
{
	NSString *tempDmgPath = [[path stringByAppendingPathExtension:@"tmp"] stringByAppendingPathExtension:@"dmg"],
			 *dmgPath = [path stringByAppendingPathExtension:@"dmg"];
	NSTask *t = [[NSTask alloc] init];
	[t setLaunchPath:@"/usr/bin/hdiutil"];
	[t setArguments:[NSArray arrayWithObjects: // Create disk image
		@"create", 
		@"-fs", @"HFS+", 
		@"-format", @"UDRW",
		@"-ov", 
		@"-srcfolder", path, 
		tempDmgPath, nil]];
	[t launch];
	[t waitUntilExit];
	[t release];
	
	/*	t = [NSTask new];
	[t setLaunchPath:@"/usr/bin/hdiutil"];
	[t setArguments:[NSArray arrayWithObjects:@"compact", tempDmgPath, nil]]; // Compact disk image
	[t launch];
	[t waitUntilExit];
	[t release];*/
	
	t = [NSTask new];
	[t setLaunchPath:@"/usr/bin/hdiutil"];
	[t setArguments:[NSArray arrayWithObjects: // Convert to a compressed image
		@"convert", tempDmgPath,
		@"-format", @"UDZO",
		@"-o", dmgPath, nil]];
	[t launch];
	[t waitUntilExit];
	[t release];
	
	// Cleanup temp disk image
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeFileAtPath:tempDmgPath handler:nil];
}

-(void)undmg:(NSString *)path
{
	NSTask *t = [NSTask new];
	[t setLaunchPath:@"/usr/bin/hdiutil"];
	[t setArguments:[NSArray arrayWithObjects:@"mount", path, nil]];
	[t launch];
	[t waitUntilExit];
	[t release];
}

-(void)zip:(NSString *)path
{
	NSTask *t = [[NSTask alloc] init];
	[t setLaunchPath:@"/usr/bin/ditto"];
	[t setArguments:[NSArray arrayWithObjects:@"-c", @"-k", @"-rsrc", @"--keepParent", path,
		[path stringByAppendingString:@".zip"], nil]];
	[t launch];		
}

-(void)unzip:(NSString *)path
{
	NSTask *t = [[NSTask alloc] init];
	[t setLaunchPath:@"/usr/bin/ditto"];
	[t setArguments:[NSArray arrayWithObjects:@"-x", @"-k", @"-rsrc", path,
		[path stringByDeletingPathExtension], nil]];
	[t launch];
}

#pragma mark -
#pragma mark Private methods

-(void)sendMessage:(NSString *)msg
{
	if (_delegate && [_delegate respondsToSelector:@selector(compressor:sentMessage:)])
		[_delegate compressor:self sentMessage:msg];
}

-(void)postProgress:(NSNumber *)progress
{
	NSLog(@"%s %@", _cmd, progress);
	if (_delegate && [_delegate respondsToSelector:@selector(compressor:operationProgressedTo:)])
		[_delegate compressor:self operationProgressedTo:progress];
}

- (void)receivedTaskData:(NSNotification *)aNotification
{
	NSLog(@"%s %@", _cmd, aNotification);
}

@end
