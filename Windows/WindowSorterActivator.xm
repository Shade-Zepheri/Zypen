#import <libactivator/libactivator.h>
#import "ZYDesktopManager.h"
#import "ZYDesktopWindow.h"
#import "ZYHostedAppView.h"
#import "ZYWindowBar.h"
#import "ZYWindowSorter.h"

@interface ZYActivatorSortWindowsListener : NSObject <LAListener>
@end

static ZYActivatorSortWindowsListener *sharedInstance$ZYActivatorSortWindowsListener;

@implementation ZYActivatorSortWindowsListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    ZYDesktopWindow *desktop = ZYDesktopManager.sharedInstance.currentDesktop;

    [ZYWindowSorter sortWindowsOnDesktop:desktop resizeIfNecessary:YES];
}
@end

%ctor {
    IF_SPRINGBOARD {
        sharedInstance$ZYActivatorSortWindowsListener = [[ZYActivatorSortWindowsListener alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance$ZYActivatorSortWindowsListener forName:@"com.shade.zypen.empoleon.sortWindows"];
    }
}
