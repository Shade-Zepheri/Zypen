#import "ZYDesktopWindow.h"

@interface ZYWindowSorter : NSObject
+ (void)sortWindowsOnDesktop:(ZYDesktopWindow*)desktop resizeIfNecessary:(BOOL)resize;
@end
