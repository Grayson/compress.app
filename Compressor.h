//
//  Compressor.h
//  Compress
//
//  Created by Grayson Hansard on 8/3/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <stdio.h>
#include <zlib.h>
#include <bzlib.h>
#include <fcntl.h>

@interface Compressor : NSObject {
	id _delegate;
}

+(id)compressor;
+(NSArray *)compressionMethodsForFiles;
+(NSArray *)compressionMethodsForFolders;
+(NSArray *)compressionFileTypes;

-(void)compressFileAtPath:(NSString *)path operation:(NSString *)op;
- (void)decompressFileAtPath:(NSString *)path;

-(id)delegate;
-(void)setDelegate:(id)delegate;

-(void)tar:(NSString *)path;
-(void)untar:(NSString *)path;

-(void)gzip:(NSString *)path;
-(void)gunzip:(NSString *)path;

-(void)zip:(NSString *)path;
-(void)unzip:(NSString *)path;

-(void)bzip2:(NSString *)path;
-(void)bunzip2:(NSString *)path;

-(void)p7zip:(NSString *)path;
-(void)unp7zip:(NSString *)path;

-(void)dmg:(NSString *)path;
-(void)undmg:(NSString *)path;

@end

@interface NSObject (CompressorDelegate)
-(void)compressorWillBegin:(Compressor *)compressor;
-(void)compressor:(Compressor *)compressor operationProgressedTo:(NSNumber *)percent;
-(void)compressor:(Compressor *)compressor sentMessage:(NSString *)message;
-(void)compressorDidEnd:(Compressor *)compressor archivePath:(NSString *)path;
@end