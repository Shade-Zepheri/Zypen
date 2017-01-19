#import <objc/runtime.h>
#import "ZYReachabilityManager.h"
#import "headers.h"
#import "ZYAppSliderProviderView.h"
#import "ZYMessagingServer.h"

@implementation ZYReachabilityManager
+ (instancetype)sharedInstance {
	SHARED_INSTANCE(ZYReachabilityManager);
}

- (void)launchTopAppWithIdentifier:(NSString*)identifier {
	//[[objc_getClass("SBWorkspace") sharedInstance] ZY_closeCurrentView];
	[[objc_getClass("SBMainWorkspace") _instanceIfExists] ZY_launchTopAppWithIdentifier:identifier];
}

- (void)launchWidget:(ZYWidget*)widget {
	//[[objc_getClass("SBWorkspace") sharedInstance] ZY_closeCurrentView];
	[[objc_getClass("SBMainWorkspace") _instanceIfExists] ZY_setView:[widget view] preferredHeight:[widget preferredHeight]];
}

- (void)showWidgetSelector {
	//[[objc_getClass("SBWorkspace") sharedInstance] ZY_closeCurrentView];
	[[objc_getClass("SBMainWorkspace") _instanceIfExists] ZY_showWidgetSelector];
}

- (void)showAppWithSliderProvider:(__weak ZYAppSliderProviderView*)view {
	//[[objc_getClass("SBWorkspace") sharedInstance] ZY_closeCurrentView];
	[view updateCurrentView];
	[view load];
	[[objc_getClass("SBMainWorkspace") _instanceIfExists] ZY_setView:view preferredHeight:view.frame.size.height];
}

@end
