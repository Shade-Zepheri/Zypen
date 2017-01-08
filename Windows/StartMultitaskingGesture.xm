#import "headers.h"
#import "ZYDesktopManager.h"
#import "ZYGestureManager.h"
#import "ZYSettings.h"
#import "ZYHostManager.h"
#import "ZYBackgrounder.h"
#import "ZYWindowStatePreservationSystemManager.h"
#import "ZYControlCenterInhibitor.h"
#import "Zypen.h"

BOOL locationIsInValidArea(CGFloat x) {
    if (x == 0) {
      return YES; // more than likely, UIGestureRecognizerStateEnded
    }
    switch ([ZYSettings.sharedSettings windowedMultitaskingGrabArea]) {
        case ZYGrabAreaBottomLeftThird:
        HBLogDebug(@"[ReachApp] StartMultitaskingGesture: %f %f", x, UIScreen.mainScreen.ZY_interfaceOrientedBounds.size.width);
            return x <= UIScreen.mainScreen.ZY_interfaceOrientedBounds.size.width / 3.0;
        case ZYGrabAreaBottomMiddleThird:
            return x >= UIScreen.mainScreen.ZY_interfaceOrientedBounds.size.width / 3.0 && x <= (UIScreen.mainScreen.ZY_interfaceOrientedBounds.size.width / 3.0) * 2;
        case ZYGrabAreaBottomRightThird:
            return x >= (UIScreen.mainScreen.ZY_interfaceOrientedBounds.size.width / 3.0) * 2;
        default:
            return NO;
    }
}

%ctor {
    IF_NOT_SPRINGBOARD {
      return;
    }
    __weak __block UIView *appView = nil;
    __block CGFloat lastY = 0;
    __block CGPoint originalCenter;
    [ZYGestureManager.sharedInstance addGestureRecognizer:^ZYGestureCallbackResult(UIGestureRecognizerState state, CGPoint location, CGPoint velocity) {

        SBApplication *topApp = UIApplication.sharedApplication._accessibilityFrontMostApplication;

        // Dismiss potential CC
        //[[%c(SBUIController) sharedInstance] _showControlCenterGestureEndedWithLocation:CGPointMake(0, UIScreen.mainScreen.bounds.size.height - 1) velocity:CGPointZero];

        if (state == UIGestureRecognizerStateBegan) {
            [ZYControlCenterInhibitor setInhibited:YES];

            // Show HS/Wallpaper
            [[%c(SBWallpaperController) sharedInstance] beginRequiringWithReason:@"BeautifulAnimation"];
            [[%c(SBUIController) sharedInstance] restoreContentAndUnscatterIconsAnimated:NO];

            // Assign view
            appView = [ZYHostManager systemHostViewForApplication:topApp].superview;
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
              appView = appView.superview;
            }
            originalCenter = appView.center;
        } else if (state == UIGestureRecognizerStateChanged) {
            lastY = location.y;
            CGFloat scale = location.y / UIScreen.mainScreen.ZY_interfaceOrientedBounds.size.height;

            if ([ZYWindowStatePreservationSystemManager.sharedInstance hasWindowInformationForIdentifier:topApp.bundleIdentifier]) {
                scale = MIN(MAX(scale, 0.01), 1);
                CGFloat actualScale = scale;
                scale = 1 - scale;
                ZYPreservedWindowInformation info = [ZYWindowStatePreservationSystemManager.sharedInstance windowInformationForAppIdentifier:topApp.bundleIdentifier];

                // Interpolates between A and B with percentage T (T% between state A and state B)
                CGFloat (^interpolate)(CGFloat, CGFloat, CGFloat) = ^CGFloat(CGFloat a, CGFloat b, CGFloat t){
                    return a + (b - a) * t;
                };

                CGPoint center = CGPointMake(
                    interpolate(info.center.x, originalCenter.x, actualScale),
                    interpolate(info.center.y, originalCenter.y, actualScale)
                );

                CGFloat currentRotation = (atan2(info.transform.b, info.transform.a) * scale);
                //CGFloat currentScale = 1 - (sqrt(info.transform.a * info.transform.a + info.transform.c * info.transform.c) * scale);
                CGFloat currentScale = interpolate(1, sqrt(info.transform.a * info.transform.a + info.transform.c * info.transform.c), scale);
                CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformMakeScale(currentScale, currentScale), currentRotation);

                appView.center = center;
                appView.transform = transform;
            } else {
                scale = MIN(MAX(scale, 0.3), 1);
                appView.transform = CGAffineTransformMakeScale(scale, scale);
            }
        } else if (state == UIGestureRecognizerStateEnded) {
            [ZYControlCenterInhibitor setInhibited:NO];

            if (lastY <= (UIScreen.mainScreen.ZY_interfaceOrientedBounds.size.height / 4) * 3 && lastY != 0) {
                [UIView animateWithDuration:.3 animations:^{

                    if ([ZYWindowStatePreservationSystemManager.sharedInstance hasWindowInformationForIdentifier:topApp.bundleIdentifier]) {
                        ZYPreservedWindowInformation info = [ZYWindowStatePreservationSystemManager.sharedInstance windowInformationForAppIdentifier:topApp.bundleIdentifier];
                        appView.center = info.center;
                        appView.transform = info.transform;
                    } else {
                        appView.transform = CGAffineTransformMakeScale(0.5, 0.5);
                        appView.center = originalCenter;
                    }
                } completion:^(BOOL _) {
                    ZYIconIndicatorViewInfo indicatorInfo = [[%c(ZYBackgrounder) sharedInstance] allAggregatedIndicatorInfoForIdentifier:topApp.bundleIdentifier];

                    // Close app
                    [[%c(ZYBackgrounder) sharedInstance] temporarilyApplyBackgroundingMode:ZYBackgroundModeForcedForeground forApplication:topApp andCloseForegroundApp:NO];
                    FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
                        SBAppToAppWorkspaceTransaction *transaction = [Zypen createSBAppToAppWorkspaceTransactionForExitingApp:topApp];
                        [transaction begin];

                        // Open in window
                        ZYWindowBar *windowBar = [ZYDesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:topApp animated:YES];
                        if (ZYDesktopManager.sharedInstance.lastUsedWindow == nil) {
                          ZYDesktopManager.sharedInstance.lastUsedWindow = windowBar;
                        }
                    }];
                    [(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];
                    [[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"BeautifulAnimation"];

                    // Pop forced foreground backgrounding
                    [[%c(ZYBackgrounder) sharedInstance] queueRemoveTemporaryOverrideForIdentifier:topApp.bundleIdentifier];
                    [[%c(ZYBackgrounder) sharedInstance] removeTemporaryOverrideForIdentifier:topApp.bundleIdentifier];
                    [[%c(ZYBackgrounder) sharedInstance] updateIconIndicatorForIdentifier:topApp.bundleIdentifier withInfo:indicatorInfo];
                }];
            } else {
                appView.center = originalCenter;
                [UIView animateWithDuration:0.2 animations:^{ appView.transform = CGAffineTransformIdentity; } completion:^(BOOL _) {
                    [[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"BeautifulAnimation"];
                }];
            }
            appView = nil;
        }

        return ZYGestureCallbackResultSuccess;
    } withCondition:^BOOL(CGPoint location, CGPoint velocity) {
        return [ZYSettings.sharedSettings windowedMultitaskingEnabled] && (locationIsInValidArea(location.x) || appView) && ![[%c(SBUIController) sharedInstance] isAppSwitcherShowing] && ![[%c(SBLockScreenManager) sharedInstance] isUILocked] && [UIApplication.sharedApplication _accessibilityFrontMostApplication] != nil && ![[%c(SBNotificationCenterController) sharedInstance] isVisible];
    } forEdge:UIRectEdgeBottom identifier:@"com.shade.zypen.empoleon.systemgesture" priority:ZYGesturePriorityDefault];
}
