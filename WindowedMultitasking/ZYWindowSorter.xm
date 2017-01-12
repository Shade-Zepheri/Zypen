#import "ZYWindowSorter.h"
#import "headers.h"
#import "ZYWindowBar.h"
#import "ZYWindowSnapDataProvider.h"

@implementation ZYWindowSorter
+ (void)sortWindowsOnDesktop:(ZYDesktopWindow*)desktop resizeIfNecessary:(BOOL)resize {
	NSInteger numberOfWindows = desktop.hostedWindows.count;

	if (numberOfWindows == 0) {
    return;
  }

	NSMutableArray *windows = [NSMutableArray array];
	for (UIView *view in desktop.subviews) {
    if ([view isKindOfClass:[ZYWindowBar class]]) {
      [windows addObject:view];
    }
  }

	if (numberOfWindows == 1) {
		if (resize) {
      [windows[0] scaleTo:0.7 animated:YES derotate:YES];
    }
		[ZYWindowSnapDataProvider snapWindow:windows[0] toLocation:ZYWindowSnapLocationLeftTop animated:YES];
	} else if (numberOfWindows == 2) {
		ZYWindowBar *window1 = windows[0];
		ZYWindowBar *window2 = windows[1];

		if (resize) {
			[window1 scaleTo:0.5 animated:YES derotate:YES];
			[window2 scaleTo:0.5 animated:YES derotate:YES];
		}

		[ZYWindowSnapDataProvider snapWindow:window1 toLocation:ZYWindowSnapLocationLeftTop animated:YES];
		[ZYWindowSnapDataProvider snapWindow:window2 toLocation:ZYWindowSnapLocationRightTop animated:YES];
	} else if (numberOfWindows == 3) {
		ZYWindowBar *window1 = windows[0];
		ZYWindowBar *window2 = windows[1];
		ZYWindowBar *window3 = windows[2];

		if (resize) {
			[window1 scaleTo:0.5 animated:YES derotate:YES];
			[window2 scaleTo:0.5 animated:YES derotate:YES];
			[window3 scaleTo:0.4 animated:YES derotate:YES];
		}

		[ZYWindowSnapDataProvider snapWindow:window1 toLocation:ZYWindowSnapLocationLeftTop animated:YES];
		[ZYWindowSnapDataProvider snapWindow:window2 toLocation:ZYWindowSnapLocationRightTop animated:YES];
		[ZYWindowSnapDataProvider snapWindow:window3 toLocation:ZYWindowSnapLocationBottomCenter animated:YES];
	} else if (NO && numberOfWindows == 4) {
		ZYWindowBar *window1 = windows[0];
		ZYWindowBar *window2 = windows[1];
		ZYWindowBar *window3 = windows[2];
		ZYWindowBar *window4 = windows[3];

		if (resize) {
			[window1 scaleTo:0.45 animated:YES derotate:YES];
			[window2 scaleTo:0.45 animated:YES derotate:YES];
			[window3 scaleTo:0.45 animated:YES derotate:YES];
			[window4 scaleTo:0.45 animated:YES derotate:YES];
		}

		[ZYWindowSnapDataProvider snapWindow:window1 toLocation:ZYWindowSnapLocationLeftTop animated:YES];
		[ZYWindowSnapDataProvider snapWindow:window2 toLocation:ZYWindowSnapLocationRightTop animated:YES];
		[ZYWindowSnapDataProvider snapWindow:window3 toLocation:ZYWindowSnapLocationBottomLeft animated:YES];
		[ZYWindowSnapDataProvider snapWindow:window4 toLocation:ZYWindowSnapLocationBottomRight animated:YES];
	} else {
		if (resize) {
			//CGFloat maxScale = 1.0 / numberOfWindows; // (numberOfWindows / 2.0);
			//CGFloat maxScale = (desktop.frame.size.width / (numberOfWindows/2.0)) / desktop.frame.size.width;
			CGFloat factor = desktop.frame.size.height - 20;
			CGFloat maxScale = factor / (ceil(sqrt(numberOfWindows)) * [windows[0] bounds].size.height);

			CGFloat x = 0, y = 0;
			NSInteger panesPerLine = floor(1.0 / maxScale);// (numberOfWindows & ~1) /* round down to nearest even number */
			NSInteger currentPane = 0;

			for (ZYWindowBar *bar in windows) {
				[bar scaleTo:maxScale animated:YES derotate:YES];

				if (y == 0) { // 20 = statusbar
					y = 20 + (bar.frame.size.height / 2.0);
        }
				if (x == 0) {
          x = bar.frame.size.width / 2.0;
        }
				bar.center = CGPointMake(x, y);

				if (++currentPane == panesPerLine) {
					currentPane = 0;
					x = 0;
					y += bar.frame.size.height;
				} else {
          x += bar.frame.size.width;
        }
			}
		} else {

		}
	}

	for (ZYWindowBar *bar in windows) {
    [bar saveWindowInfo];
  }
}
@end
