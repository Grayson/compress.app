/* DropView */

#import <Cocoa/Cocoa.h>

@interface DropView : NSView
{
	IBOutlet id delegate;
}
@end

@interface NSObject (DropViewDelegate)
-(void)view:(NSView *)view receivedDroppedFiles:(NSArray *)files;
@end