#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#import <notify.h>
#import "headers.h"
#import "ZYWidgetSectionManager.h"
#import "ZYSettings.h"
#import "ZYAppSliderProviderView.h"
#import "ZYBackgrounder.h"
#import "ZYDesktopManager.h"
#import "ZYDesktopWindow.h"
#import "ZYMessagingServer.h"
#import "ZYAppSwitcherModelWrapper.h"
#import "Zypen.h"

UIView *view = nil;
NSString *lastBundleIdentifier = @"";
NSString *currentBundleIdentifier = @"";
UIViewController *ncViewController = nil;
UIView *draggerView = nil;

BOOL overrideOrientation = NO;
CGFloat grabberCenter_Y = -1;
CGPoint firstLocation = CGPointZero;
CGFloat grabberCenter_X = 0;
BOOL showingNC = NO;
BOOL overrideDisableForStatusBar = NO;
CGRect pre_topAppFrame = CGRectZero;
CGAffineTransform pre_topAppTransform = CGAffineTransformIdentity;
UIView *bottomDraggerView = nil;
CGFloat old_grabberCenterY = -1;

BOOL wasEnabled = NO;

%group hooks

%hook SBReachabilityManager
+ (BOOL)reachabilitySupported {
    return YES;
}

- (void)_handleReachabilityActivated {
    overrideOrientation = YES;
    %orig;
    overrideOrientation = NO;
}

- (void)enableExpirationTimerForEndedInteraction {
    if ([ZYSettings.sharedSettings disableAutoDismiss]) {
      return;
    }
    %orig;
}

- (void)_handleSignificantTimeChanged {
    if ([ZYSettings.sharedSettings disableAutoDismiss]) {
      return;
    }
    %orig;
}

- (void)_keepAliveTimerFired:(unsafe_id)arg1 {
    if ([ZYSettings.sharedSettings disableAutoDismiss]) {
      return;
    }
    %orig;
}

- (void)_setKeepAliveTimerForDuration:(double)arg1 {
    if ([ZYSettings.sharedSettings disableAutoDismiss]) {
      return;
    }
    %orig;
}

- (void)deactivateReachabilityModeForObserver:(unsafe_id)arg1 {
    if (overrideDisableForStatusBar) {
      return;
    }
    %orig;

    if (wasEnabled) {
        wasEnabled = NO;
        // Notify both top and bottom apps Reachability is closing
        if ([view isKindOfClass:[ZYAppSliderProviderView class]]) {
          [ZYMessagingServer.sharedInstance endResizingApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
          [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:NO forApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
          [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
          [(ZYAppSliderProviderView*)view unload];
          [view removeFromSuperview];
          view = nil;
        }
        if (lastBundleIdentifier && lastBundleIdentifier.length > 0) {
          [ZYMessagingServer.sharedInstance endResizingApp:lastBundleIdentifier completion:nil];
          [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:NO forApp:lastBundleIdentifier completion:nil];
          [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:lastBundleIdentifier completion:nil];
          [ZYMessagingServer.sharedInstance setHosted:NO forIdentifier:lastBundleIdentifier completion:nil];
        }
        if (currentBundleIdentifier) {
          [ZYMessagingServer.sharedInstance endResizingApp:currentBundleIdentifier completion:nil];
        }
        [GET_SBWORKSPACE ZY_closeCurrentView];
    }

}

- (void)_handleReachabilityDeactivated {
    if (overrideDisableForStatusBar) {
      return;
    }
    %orig;
}

- (void)_updateReachabilityModeActive:(_Bool)arg1 withRequestingObserver:(unsafe_id)arg2 {
    if (overrideDisableForStatusBar) {
      return;
    }
    %orig;
}
%end

%hook SBReachabilitySettings
- (CGFloat)reachabilityDefaultKeepAlive {
    if ([ZYSettings.sharedSettings disableAutoDismiss]) {
      return 9999999999;
    }
    return %orig;
}

- (CGFloat)reachabilityInteractiveKeepAlive {
    if ([ZYSettings.sharedSettings disableAutoDismiss]) {
      return 9999999999;
    }
    return %orig;
}

%end

id SBWorkspace$sharedInstance;
%hook SB_WORKSPACE_CLASS
%new + (instancetype)sharedInstance {
    return SBWorkspace$sharedInstance;
}

- (id)init {
    SBWorkspace$sharedInstance = %orig;
    return SBWorkspace$sharedInstance;
}

%new - (BOOL)isUsingReachApp {
    return (view || showingNC);
}

- (void)_exitReachabilityModeWithCompletion:(unsafe_id)arg1 {
    if (overrideDisableForStatusBar) {
      return;
    }
    %orig;
}

- (void)handleReachabilityModeDeactivated {
    if (overrideDisableForStatusBar) {
      return;
    }
    %orig;
}

%new - (void)ZY_closeCurrentView {
    if ([view isKindOfClass:[ZYAppSliderProviderView class]]) {
      [ZYMessagingServer.sharedInstance endResizingApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
      [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:NO forApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
      [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
      [(ZYAppSliderProviderView*)view unload];
      [view removeFromSuperview];
      view = nil;
    }

    [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:currentBundleIdentifier completion:nil];
    [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:NO forApp:currentBundleIdentifier completion:nil];

    if ([ZYSettings.sharedSettings showNCInstead]) {
      showingNC = NO;
      SBWindow *window = MSHookIvar<SBWindow*>(self, "_reachabilityEffectWindow");
      [window _setRotatableViewOrientation:UIInterfaceOrientationPortrait updateStatusBar:YES duration:0.0 force:YES];
      window.rootViewController = nil;
      UIViewController *viewController = [[%c(SBNotificationCenterController) performSelector:@selector(sharedInstance)] performSelector:@selector(viewController)];
      [viewController performSelector:@selector(hostWillDismiss)];
      [viewController performSelector:@selector(hostDidDismiss)];
      //[viewController.view removeFromSuperview];
    } else {
        SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:lastBundleIdentifier];

        if ([view isKindOfClass:[ZYAppSliderProviderView class]]) {
          [((ZYAppSliderProviderView*)view) unload];
        }

        // Give them a little time to receive the notifications...
        if (view) {
          if ([view superview] != nil) {
            [view removeFromSuperview];
          }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (lastBundleIdentifier && lastBundleIdentifier.length > 0) {
                if (app && [app pid] && [app mainScene]) {
                    FBScene *scene = [app mainScene];
                    FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
                    SET_BACKGROUNDED(settings, YES);
                    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];
                    //Dont Understand Purpose? MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").frame = pre_topAppFrame;
                    MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").transform = pre_topAppTransform;

                    SBApplication *currentApp = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:currentBundleIdentifier];
                    if ([currentApp mainScene]) {
                        //Dont Understand Purpose?  MSHookIvar<FBWindowContextHostView*>([currentApp mainScene].contextHostManager, "_hostView").frame = pre_topAppFrame;
                        MSHookIvar<FBWindowContextHostView*>([currentApp mainScene].contextHostManager, "_hostView").transform = pre_topAppTransform;
                    }

                    FBWindowContextHostManager *contextHostManager = [scene contextHostManager];
                    [contextHostManager disableHostingForRequester:@"Zypen"];
                }
            }
            view = nil;
            lastBundleIdentifier = nil;
        });
    }
}

- (void)_disableReachabilityImmediately:(_Bool)arg1 {
    if (overrideDisableForStatusBar) {
      return;
    }

    %orig;

    if (![ZYSettings.sharedSettings reachabilityEnabled] && wasEnabled == NO) {
      return;
    }

    if (arg1 && wasEnabled) {
        wasEnabled = NO;

        // Notify both top and bottom apps Reachability is closing
        if ([view isKindOfClass:[ZYAppSliderProviderView class]]) {
            [ZYMessagingServer.sharedInstance endResizingApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
            [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:NO forApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
            [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
            [(ZYAppSliderProviderView*)view unload];
            [view removeFromSuperview];
            view = nil;
        }
        if (lastBundleIdentifier && lastBundleIdentifier.length > 0) {
            [ZYMessagingServer.sharedInstance endResizingApp:lastBundleIdentifier completion:nil];
            [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:NO forApp:lastBundleIdentifier completion:nil];
            [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:lastBundleIdentifier completion:nil];
            [ZYMessagingServer.sharedInstance setHosted:NO forIdentifier:lastBundleIdentifier completion:nil];
        }
        if (currentBundleIdentifier) {
            [ZYMessagingServer.sharedInstance endResizingApp:currentBundleIdentifier completion:nil];
        }

        [self ZY_closeCurrentView];
        if (draggerView) {
            draggerView = nil;
        }
    }
}

- (void)handleReachabilityModeActivated {
    %orig;
    if (![ZYSettings.sharedSettings reachabilityEnabled]) {
      return;
    }
    wasEnabled = YES;

    CGFloat knobWidth = 60;
    CGFloat knobHeight = 25;
    draggerView = [[UIView alloc] initWithFrame:CGRectMake(
        (UIScreen.mainScreen.bounds.size.width / 2) - (knobWidth / 2),
        [UIScreen mainScreen].bounds.size.height * .3,
        knobWidth, knobHeight)];
    draggerView.alpha = 0.3;
    draggerView.layer.cornerRadius = 10;
    grabberCenter_X = draggerView.center.x;

    SBWindow *w = MSHookIvar<SBWindow*>(self, "_reachabilityEffectWindow");
    if ([ZYSettings.sharedSettings showNCInstead]) {
        showingNC = YES;

        if (ncViewController == nil)
            ncViewController = [[%c(SBNotificationCenterViewController) alloc] init];
        ncViewController.view.frame = (CGRect) { { 0, 0 }, w.frame.size };
        w.rootViewController = ncViewController;
        [w addSubview:ncViewController.view];

        //[[%c(SBNotificationCenterController) performSelector:@selector(sharedInstance)] performSelector:@selector(_setupForViewPresentation)];
        [ncViewController performSelector:@selector(hostWillPresent)];
        [ncViewController performSelector:@selector(hostDidPresent)];

        if ([ZYSettings.sharedSettings enableRotation]) {
            [w _setRotatableViewOrientation:UIApplication.sharedApplication.statusBarOrientation updateStatusBar:YES duration:0.0 force:YES];
        }
    } else {
        currentBundleIdentifier = UIApplication.sharedApplication._accessibilityFrontMostApplication.bundleIdentifier;
        if (!currentBundleIdentifier) {
          return;
        }

        if ([ZYSettings.sharedSettings showWidgetSelector]) {
            [self ZY_showWidgetSelector];
        } else {
            SBApplication *app = nil;
            FBScene *scene = nil;
            NSMutableArray *bundleIdentifiers = [[ZYAppSwitcherModelWrapper appSwitcherAppIdentiferList] mutableCopy];
            while (scene == nil && bundleIdentifiers.count > 0) {
                lastBundleIdentifier = bundleIdentifiers[0];

                if ([lastBundleIdentifier isEqual:currentBundleIdentifier]) {
                    [bundleIdentifiers removeObjectAtIndex:0];
                    continue;
                }

                app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:lastBundleIdentifier];
                scene = [app mainScene];
                if (!scene) {
                  if (bundleIdentifiers.count > 0) {
                    [bundleIdentifiers removeObjectAtIndex:0];
                  }
                }
            }
            if (lastBundleIdentifier == nil || lastBundleIdentifier.length == 0) {
                return;
            }

            [self ZY_launchTopAppWithIdentifier:lastBundleIdentifier];
        }
    }

    draggerView.backgroundColor = UIColor.lightGrayColor;
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    if (grabberCenter_Y == -1)
        grabberCenter_Y = w.frame.size.height - (knobHeight / 2);
    if (grabberCenter_Y < 0)
        grabberCenter_Y = UIScreen.mainScreen.bounds.size.height * 0.3;
    draggerView.center = CGPointMake(grabberCenter_X, grabberCenter_Y);
    recognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    [draggerView addGestureRecognizer:recognizer];

    UILongPressGestureRecognizer *recognizer2 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(ZY_handleLongPress:)];
    recognizer2.delegate = (id<UIGestureRecognizerDelegate>)self;
    [draggerView addGestureRecognizer:recognizer2];

    UITapGestureRecognizer *recognizer3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ZY_detachAppAndClose:)];
    recognizer3.numberOfTapsRequired = 2;
    recognizer3.delegate = (id<UIGestureRecognizerDelegate>)self;
    [draggerView addGestureRecognizer:recognizer3];

    [w addSubview:draggerView];

    if ([ZYSettings.sharedSettings showBottomGrabber]) {
        bottomDraggerView = [[UIView alloc] initWithFrame:CGRectMake(
            (UIScreen.mainScreen.bounds.size.width / 2) - (knobWidth / 2),
            -(knobHeight / 2),
            knobWidth, knobHeight)];
        bottomDraggerView.alpha = 0.3;
        bottomDraggerView.layer.cornerRadius = 10;
        bottomDraggerView.backgroundColor = UIColor.lightGrayColor;
        [bottomDraggerView addGestureRecognizer:recognizer];
        [MSHookIvar<SBWindow*>(self,"_reachabilityWindow") addSubview:bottomDraggerView];
    }

    // Update sizes of reachability (and their contained apps) and the location of the dragger view
    [self updateViewSizes:draggerView.center animate:NO];
}

%new - (void)ZY_showWidgetSelector {
    if (view) {
      [self ZY_closeCurrentView];
    }

    SBWindow *w = MSHookIvar<SBWindow*>(self, "_reachabilityEffectWindow");
    static CGSize fullSize = [%c(SBIconView) defaultIconSize];
    fullSize.height = fullSize.width; // otherwise it often looks like {60,74}
    CGFloat padding = 20;

    NSInteger numIconsPerLine = 0;
    CGFloat tmpWidth = 10;
    while (tmpWidth + fullSize.width <= w.frame.size.width) {
        numIconsPerLine++;
        tmpWidth += fullSize.width + 20;
    }
    padding = (w.frame.size.width - (numIconsPerLine * fullSize.width)) / numIconsPerLine;

    UIView *widgetSelectorView = [ZYWidgetSectionManager.sharedInstance createViewForEnabledSectionsWithBaseFrame:w.frame preferredIconSize:fullSize iconsThatFitPerLine:numIconsPerLine spacing:padding];
    widgetSelectorView.frame = (CGRect){ { 0, 0 }, widgetSelectorView.frame.size };
    //widgetSelectorView.frame = w.frame;

    if (draggerView) {
      [w insertSubview:widgetSelectorView belowSubview:draggerView];
    } else {
      [w addSubview:widgetSelectorView];
    }
    view = widgetSelectorView;

    if ([ZYSettings.sharedSettings autoSizeWidgetSelector]) {
        CGFloat moddedHeight = widgetSelectorView.frame.size.height;
        if (old_grabberCenterY == -1)
            old_grabberCenterY = UIScreen.mainScreen.bounds.size.height * 0.3;
        old_grabberCenterY = grabberCenter_Y;
        grabberCenter_Y = moddedHeight;
    }
    CGPoint newCenter = CGPointMake(draggerView.center.x, grabberCenter_Y);
    draggerView.center = newCenter;
    draggerView.hidden = YES;
    [self updateViewSizes:newCenter animate:YES];
}

CGFloat startingY = -1;
%new - (void)handlePan:(UIPanGestureRecognizer*)sender {
    UIView *view = draggerView; //sender.view;

    if (sender.state == UIGestureRecognizerStateBegan) {
        startingY = grabberCenter_Y;
        grabberCenter_X = view.center.x;
        firstLocation = view.center;
        grabberCenter_Y = [sender locationInView:view.superview].y;
        draggerView.alpha = 0.8;
        bottomDraggerView.alpha = 0;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [sender translationInView:view];

        if (firstLocation.y + translation.y < 50) {
            view.center = CGPointMake(grabberCenter_X, 50);
            grabberCenter_Y = 50;
        } else if (firstLocation.y + translation.y > UIScreen.mainScreen.bounds.size.height - 30) {
            view.center = CGPointMake(grabberCenter_X, UIScreen.mainScreen.bounds.size.height - 30);
            grabberCenter_Y = UIScreen.mainScreen.bounds.size.height - 30;
        } else {
            view.center = CGPointMake(grabberCenter_X, firstLocation.y + translation.y);
            grabberCenter_Y = [sender locationInView:view.superview].y;
        }

        [self updateViewSizes:view.center animate:YES];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        draggerView.alpha = 0.3;
        bottomDraggerView.alpha = 0.3;
        if (startingY != -1 && fabs(grabberCenter_Y - startingY) < 3) {
          [self ZY_handleLongPress:nil];
        }
        startingY = -1;
        [self updateViewSizes:view.center animate:YES];
    }
}

%new - (void)ZY_handleLongPress:(UILongPressGestureRecognizer*)gesture {
    [self ZY_showWidgetSelector];
}

%new - (void)ZY_detachAppAndClose:(UITapGestureRecognizer*)gesture {
    NSString *ident = lastBundleIdentifier;
    if ([view isKindOfClass:[ZYAppSliderProviderView class]]) {
        ZYAppSliderProviderView *temp = (ZYAppSliderProviderView*)view;
        ident = temp.currentBundleIdentifier;
        [temp unload];
    }

    if (!ident || ident.length == 0) {
      return;
    }

    [self handleReachabilityModeDeactivated];
    SBApplication *app = [[%c(SBApplicationController) sharedInstance] ZY_applicationWithBundleIdentifier:ident];
    ZYIconIndicatorViewInfo indicatorInfo = [[%c(ZYBackgrounder) sharedInstance] allAggregatedIndicatorInfoForIdentifier:ident];

    [[%c(ZYBackgrounder) sharedInstance] temporarilyApplyBackgroundingMode:ZYBackgroundModeForcedForeground forApplication:app andCloseForegroundApp:NO];
    SBDeactivationSettings *deactiveSets = [[%c(SBDeactivationSettings) alloc] init];
    [deactiveSets setFlag:YES forDeactivationSetting:20];
    [deactiveSets setFlag:NO forDeactivationSetting:2];
    [app _setDeactivationSettings:deactiveSets];

    [ZYDesktopManager.sharedInstance.currentDesktop createAppWindowWithIdentifier:ident animated:YES];

    // Pop forced foreground backgrounding
    [[%c(ZYBackgrounder) sharedInstance] queueRemoveTemporaryOverrideForIdentifier:ident];
    [[%c(ZYBackgrounder) sharedInstance] removeTemporaryOverrideForIdentifier:ident];
    [[%c(ZYBackgrounder) sharedInstance] updateIconIndicatorForIdentifier:ident withInfo:indicatorInfo];
}

%new - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([view isKindOfClass:[UIScrollView class]]) {
      return NO;
    }
    return YES;
}

%new - (void)ZY_updateViewSizes {
    [self updateViewSizes:draggerView.center animate:YES];
}

%new - (void)updateViewSizes:(CGPoint)center animate:(BOOL)animate {
    // Resizing
    SBWindow *topWindow = MSHookIvar<SBWindow*>(self, "_reachabilityEffectWindow");
    SBWindow *bottomWindow = MSHookIvar<SBWindow*>(self, "_reachabilityWindow");

    CGRect topFrame = CGRectMake(topWindow.frame.origin.x, topWindow.frame.origin.y, topWindow.frame.size.width, center.y);
    CGRect bottomFrame = CGRectMake(bottomWindow.frame.origin.x, center.y, bottomWindow.frame.size.width, UIScreen.mainScreen._referenceBounds.size.height - center.y);

    if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
        topFrame = CGRectMake(topWindow.frame.origin.x, 0, topWindow.frame.size.width, center.y);
        bottomFrame = CGRectMake(bottomWindow.frame.origin.x, center.y, bottomWindow.frame.size.width, UIScreen.mainScreen._referenceBounds.size.height - center.y);
    } else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown) {

    }

    if ([view isKindOfClass:[ZYAppSliderProviderView class]]) {
        ZYAppSliderProviderView *sliderView = (ZYAppSliderProviderView*)view;
        sliderView.frame = topFrame;
    }

    /*if ([ZYSettings.sharedSettings flipTopAndBottom])
    {
        CGRect tmp = topFrame;
        topFrame = bottomFrame;
        bottomFrame = tmp;
    }*/

    if (animate) {
        [UIView animateWithDuration:0.3 animations:^{
            bottomWindow.frame = bottomFrame;
            topWindow.frame = topFrame;
            if (view && [view isKindOfClass:[UIScrollView class]]) {
              view.frame = topFrame;
            }
        }];
    } else {
        bottomWindow.frame = bottomFrame;
        topWindow.frame = topFrame;
        if (view && [view isKindOfClass:[UIScrollView class]]) {
          view.frame = topFrame;
        }
    }

    if ([ZYSettings.sharedSettings showNCInstead]) {
        if (ncViewController) {
          ncViewController.view.frame = (CGRect) { { 0, 0 }, topFrame.size };
        }
    } else if (lastBundleIdentifier != nil || [view isKindOfClass:[ZYAppSliderProviderView class]]) {
        // Notify clients

        CGFloat width = - 1, height = -1;

        if ([view isKindOfClass:[ZYAppSliderProviderView class]]) {
            ZYAppSliderProviderView *sliderView = (ZYAppSliderProviderView*)view;
            //width = sliderView.clientFrame.size.width;
            //height = sliderView.clientFrame.size.height;


            if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
                width = center.y;
                height = topWindow.frame.size.width;
            } else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
                //width = topWindow.frame.size.height;
                width = bottomWindow.frame.origin.y;
                height = topWindow.frame.size.width;
            } else {
                width = sliderView.clientFrame.size.width;
                height = sliderView.clientFrame.size.height;
            }
        } else {
            if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
                width = center.y;
                height = topWindow.frame.size.width;
            } else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
                width = bottomWindow.frame.origin.y;
                height = topWindow.frame.size.width;
            } else {
                width = topWindow.frame.size.width;
                height = topWindow.frame.size.height;
            }
        }

        NSString *targetIdentifier = lastBundleIdentifier;
        if ([view isKindOfClass:[ZYAppSliderProviderView class]]) {
            targetIdentifier = [((ZYAppSliderProviderView*)view) currentBundleIdentifier];
        }

        if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
            [ZYMessagingServer.sharedInstance moveApp:targetIdentifier toOrigin:CGPointMake(bottomWindow.frame.size.height, 0) completion:nil];
        }
        [ZYMessagingServer.sharedInstance resizeApp:targetIdentifier toSize:CGSizeMake(width, height) completion:nil];
    }
    /* Causing Problems for Now
    if ([view isKindOfClass:[%c(FBWindowContextHostWrapperView) class]] == NO && [view isKindOfClass:[ZYAppSliderProviderView class]] == NO) {
        return; // only resize when the app is being shown. That way it's more like native Reachability
    }
    */
    [ZYMessagingServer.sharedInstance setHosted:YES forIdentifier:currentBundleIdentifier completion:nil];

    [ZYMessagingServer.sharedInstance rotateApp:lastBundleIdentifier toOrientation:[UIApplication sharedApplication].statusBarOrientation completion:nil];

    CGFloat width = -1, height = -1;

    if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        width = bottomWindow.frame.size.height;
        height = bottomWindow.frame.size.width;
    } else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
        //width = center.y;
        width = bottomWindow.frame.size.height;
        height = bottomWindow.frame.size.width;

        [ZYMessagingServer.sharedInstance moveApp:currentBundleIdentifier toOrigin:CGPointMake(bottomWindow.frame.origin.y, 0) completion:nil];
    } else {
        width = bottomWindow.frame.size.width;
        height = bottomWindow.frame.size.height;
    }
    [ZYMessagingServer.sharedInstance resizeApp:currentBundleIdentifier toSize:CGSizeMake(width, height) completion:nil];
    [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:YES forApp:currentBundleIdentifier completion:nil];

    if ([ZYSettings.sharedSettings unifyStatusBar]) {
        [ZYMessagingServer.sharedInstance forceStatusBarVisibility:NO forApp:currentBundleIdentifier completion:nil];
    }
}

%new - (void)ZY_launchTopAppWithIdentifier:(NSString*)bundleIdentifier {
    SBWindow *w = MSHookIvar<SBWindow*>(self, "_reachabilityEffectWindow");
    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:lastBundleIdentifier];
    FBScene *scene = [app mainScene];
    if (app == nil) {
        return;
    }

    [ZYMessagingServer.sharedInstance setHosted:YES forIdentifier:app.bundleIdentifier completion:nil];
    [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:YES forApp:app.bundleIdentifier completion:nil];
    [ZYMessagingServer.sharedInstance rotateApp:app.bundleIdentifier toOrientation:[UIApplication sharedApplication].statusBarOrientation completion:nil];
    [ZYMessagingServer.sharedInstance forceStatusBarVisibility:YES forApp:app.bundleIdentifier completion:nil];

    if (![app pid] || [app mainScene] == nil) {
        overrideDisableForStatusBar = YES;
        [UIApplication.sharedApplication launchApplicationWithIdentifier:bundleIdentifier suspended:YES];
        [[%c(FBProcessManager) sharedInstance] createApplicationProcessForBundleID:bundleIdentifier];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self ZY_launchTopAppWithIdentifier:bundleIdentifier];
            [self updateViewSizes:draggerView.center animate:YES];
        });
        return;
    }

    [ZYAppSwitcherModelWrapper addIdentifierToFront:bundleIdentifier];

    FBWindowContextHostManager *contextHostManager = [scene contextHostManager];

    FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
    SET_BACKGROUNDED(settings, NO);
    [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];

    [UIApplication.sharedApplication launchApplicationWithIdentifier:bundleIdentifier suspended:YES];

    [contextHostManager enableHostingForRequester:@"Zypen" orderFront:YES];
    view = [contextHostManager hostViewForRequester:@"Zypen" enableAndOrderFront:YES];

    view.accessibilityHint = bundleIdentifier;

    if (draggerView && draggerView.superview == w) {
        [w insertSubview:view belowSubview:draggerView];
    } else {
        [w addSubview:view];
    }

    //if ([ZYSettings.sharedSettings enableRotation] && ![ZYSettings.sharedSettings scalingRotationMode])
    {
        [ZYMessagingServer.sharedInstance rotateApp:lastBundleIdentifier toOrientation:[UIApplication sharedApplication].statusBarOrientation completion:nil];
    }
    /*else if ([ZYSettings.sharedSettings scalingRotationMode] && [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
    {
        overrideDisableForStatusBar = YES;
        // Force portrait
        [ZYMessagingServer.sharedInstance rotateApp:lastBundleIdentifier toOrientation:UIInterfaceOrientationPortrait completion:nil];
        [ZYMessagingServer.sharedInstance rotateApp:currentBundleIdentifier toOrientation:UIInterfaceOrientationPortrait completion:nil];
        // Scale app
        CGFloat scale = view.frame.size.width / UIScreen.mainScreen._referenceBounds.size.height;
        pre_topAppTransform = MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").transform;
        MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeRotation(M_PI_2));
        pre_topAppFrame = MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").frame;
        MSHookIvar<FBWindowContextHostView*>([app mainScene].contextHostManager, "_hostView").frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
        UIWindow *window = MSHookIvar<UIWindow*>(self,"_reachabilityEffectWindow");
        window.frame = (CGRect) { window.frame.origin, { window.frame.size.width, view.frame.size.width } };
        window = MSHookIvar<UIWindow*>(self,"_reachabilityWindow");
        window.frame = (CGRect) { { window.frame.origin.x, view.frame.size.width }, { window.frame.size.width, view.frame.size.width } };

        SBApplication *currentApp = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:currentBundleIdentifier];
        if ([currentApp mainScene]) // just checking...
        {
            MSHookIvar<FBWindowContextHostView*>([currentApp mainScene].contextHostManager, "_hostView").transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeRotation(M_PI_2));
            MSHookIvar<FBWindowContextHostView*>([currentApp mainScene].contextHostManager, "_hostView").frame = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
        }
        // Gotta for the animations to finish... ;_;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            overrideDisableForStatusBar = NO;
        });
    }*/
    draggerView.hidden = NO;
    overrideDisableForStatusBar = NO;
}

%new - (void)ZY_setView:(UIView*)view_ preferredHeight:(CGFloat)pHeight {
    view_.hidden = NO;
    SBWindow *w = MSHookIvar<SBWindow*>(self, "_reachabilityEffectWindow");
    if (view) {
        if ([view isKindOfClass:[ZYAppSliderProviderView class]]) {
            [ZYMessagingServer.sharedInstance endResizingApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
            [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:NO forApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
            [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:[((ZYAppSliderProviderView*)view) currentBundleIdentifier] completion:nil];
            [(ZYAppSliderProviderView*)view unload];
        }
        [view removeFromSuperview];
        view = nil;
    }
    view = view_;
    [w addSubview:view];
    if (draggerView && draggerView.superview) {
        [draggerView.superview bringSubviewToFront:draggerView];
    }

    CGPoint center = (CGPoint){ draggerView.center.x, pHeight <= 0 ? draggerView.center.y : pHeight };
    [self updateViewSizes:center animate:YES];
    draggerView.hidden = NO;
    draggerView.center = center;

    if ([view isKindOfClass:[ZYAppSliderProviderView class]]) {
        NSString *targetIdentifier = ((ZYAppSliderProviderView*)view).currentBundleIdentifier;
        [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:YES forApp:targetIdentifier completion:nil];
        [ZYMessagingServer.sharedInstance rotateApp:targetIdentifier toOrientation:[UIApplication sharedApplication].statusBarOrientation completion:nil];
        [ZYMessagingServer.sharedInstance forceStatusBarVisibility:YES forApp:targetIdentifier completion:nil];
    }
}

%new - (void)ZY_animateWidgetSelectorOut:(id)completion {
    [UIView animateWithDuration:0.3
    animations:^{
        view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.01, 0.01);
        view.alpha = 0;
    }
    completion:completion];
}

%new - (void)appViewItemTap:(UITapGestureRecognizer*)sender {
    NSInteger pid = [sender.view tag];
    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithPid:pid];
    if (!app) {
        app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:sender.view.restorationIdentifier];
    }

    if (app) {
        // before we re-assign view...
        [self ZY_animateWidgetSelectorOut:^(BOOL a){
            [view removeFromSuperview];
            view = nil;

            lastBundleIdentifier = app.bundleIdentifier;
            [self ZY_launchTopAppWithIdentifier:app.bundleIdentifier];

            if ([ZYSettings.sharedSettings autoSizeWidgetSelector]) {
                if (old_grabberCenterY == -1) {
                    old_grabberCenterY = UIScreen.mainScreen.bounds.size.height * 0.3;
                }
                grabberCenter_Y = old_grabberCenterY;
                draggerView.center = CGPointMake(grabberCenter_X, grabberCenter_Y);
            }
            [self updateViewSizes:draggerView.center animate:YES];
         }];
    }
}
%end

%hook SpringBoard
- (UIInterfaceOrientation)activeInterfaceOrientation {
    return overrideOrientation ? UIInterfaceOrientationPortrait : %orig;
}
%end

%end

%ctor {
    IF_SPRINGBOARD {
        Class c = objc_getClass("SBMainWorkspace") ?: objc_getClass("SBWorkspace");
        %init(hooks, SB_WORKSPACE_CLASS=c);
    }
}
