#import "DropView.h"

@implementation DropView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (delegate && [delegate respondsToSelector:@selector(view:receivedDroppedFiles:)])
		[delegate view:self receivedDroppedFiles:[[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType]];
	return YES;
}

@end
