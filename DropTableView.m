#import "DropTableView.h"

@implementation DropTableView

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (!self) return nil;

	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	
	return self;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal 
{
	if (isLocal) return NSDragOperationNone;
	else return NSDragOperationAll;//Copy;
}

- (void)rightMouseDown:(NSEvent *)theEvent
{	
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	int i = [self rowAtPoint:p];
	
	if (i < [self numberOfRows])
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
	
	[NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:self];
}

@end
