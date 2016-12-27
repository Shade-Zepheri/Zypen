#import "ZYHostManager.h"
#import "ZYCompatibilitySystem.h"

@implementation ZYHostManager
+ (UIView*)systemHostViewForApplication:(SBApplication*)app {
	if (!app) {
		return nil;
	}
	if ([app respondsToSelector:@selector(mainScene)]) {
		return MSHookIvar<UIView*>(app.mainScene.contextHostManager, "_hostView");
	} else if ([app respondsToSelector:@selector(mainScreenContextHostManager)]) {
		return MSHookIvar<UIView*>([app mainScreenContextHostManager], "_hostView");
	}
	[ZYCompatibilitySystem showWarning:@"Unable to find valid method for accessing system context host views"];
	return nil;
}

+ (UIView*)enabledHostViewForApplication:(SBApplication*)app {
	if (!app) {
		return nil;
	}

	if ([app respondsToSelector:@selector(mainScene)]) {
	    FBScene *scene = [app mainScene];
	    FBWindowContextHostManager *contextHostManager = [scene contextHostManager];

	    FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
	    if (!settings) {
				return nil;
			}

	    [settings setBackgrounded:NO];
	    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];

			[[UIApplication sharedApplication] launchApplicationWithIdentifier:app.bundleIdentifier suspended:YES];

	    [contextHostManager enableHostingForRequester:@"Zypen" orderFront:YES];
			UIView *hostView = [contextHostManager hostViewForRequester:@"Zypen" enableAndOrderFront:YES];
			hostView.accessibilityHint = app.bundleIdentifier;
			return hostView;
	}

	[ZYCompatibilitySystem showWarning:@"Unable to find valid method for accessing context host views"];
	return nil;
}

+ (NSObject*)hostManagerForApp:(SBApplication*)app {
	if (!app) {
		return nil;
	}
	if ([app respondsToSelector:@selector(mainScene)]) {
	    FBScene *scene = [app mainScene];
	    return (NSObject*)[scene contextHostManager];
	}

	[ZYCompatibilitySystem showWarning:@"Unable to find valid method for accessing context host view managers"];
	return nil;
}
@end
