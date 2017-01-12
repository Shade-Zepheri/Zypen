#import <libactivator/libactivator.h>
#import "ZYDesktopManager.h"
#import "ZYDesktopWindow.h"
#import "ZYHostedAppView.h"
#import "ZYWindowBar.h"

@interface ZYActivatorToggleEditModeListener : NSObject <LAListener>
@end

static ZYActivatorToggleEditModeListener *sharedInstance;

@implementation ZYActivatorToggleEditModeListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    ZYDesktopWindow *desktop = ZYDesktopManager.sharedInstance.currentDesktop;

    for (ZYWindowBar *view in desktop.subviews) {
    	if ([view isKindOfClass:[ZYWindowBar class]]) {
	    	if (view.isOverlayShowing) {
          [view hideOverlay];
        } else {
          [view showOverlay];
        }
    	}
    }
}
@end

%ctor {
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        sharedInstance = [[ZYActivatorToggleEditModeListener alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance forName:@"com.shade.zypen.empoleon.toggleEditMode"];
    }
}
