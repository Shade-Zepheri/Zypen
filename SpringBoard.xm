#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#import <notify.h>
#import "ZYCompatibilitySystem.h"
#import "headers.h"
#import "ZYWidgetSectionManager.h"
#import "ZYSettings.h"
#import "ZYDesktopManager.h"
#import "ZYDesktopWindow.h"
#import "ZYSnapshotProvider.h"
#import "Asphaleia3.h"

extern BOOL overrideDisableForStatusBar;

%hook SBUIController
- (_Bool)clickedMenuButton {
  if ([ZYSettings.sharedSettings homeButtonClosesReachability] && [[%c(SBMainWorkspace) ZY_sharedInstance] isUsingReachApp] && ((SBReachabilityManager*)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive) {
      overrideDisableForStatusBar = NO;
      [[%c(SBReachabilityManager) sharedInstance] _handleReachabilityDeactivated];
      return YES;
  }

  return %orig;
}

- (BOOL)handleHomeButtonSinglePressUp {
  if ([ZYSettings.sharedSettings homeButtonClosesReachability] && [[%c(SBMainWorkspace) ZY_sharedInstance] isUsingReachApp] && ((SBReachabilityManager*)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive) {
      overrideDisableForStatusBar = NO;
      [[%c(SBReachabilityManager) sharedInstance] _handleReachabilityDeactivated];
      return YES;
  }

  return %orig;
}

// This should help fix the problems where closing an app with Tage or the iPad Gesture would cause the app to suspend(?) and lock up the device.
- (void)_suspendGestureBegan {
    %orig;
    [UIApplication.sharedApplication._accessibilityFrontMostApplication clearDeactivationSettings];
}
%end

%hook SpringBoard
- (void)_performDeferredLaunchWork {
    %orig;
    [ZYDesktopManager sharedInstance]; // load desktop (and previous windows!)

    // No applications show in the mission control until they have been launched by the user.
    // This prevents always-running apps like Mail or Pebble from perpetually showing in Mission Control.
    //[[%c(ZYMissionControlManager) sharedInstance] setInhibitedApplications:[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers]];
}
%end

%hook SBApplicationController
%new - (SBApplication*)ZY_applicationWithBundleIdentifier:(__unsafe_unretained NSString*)bundleIdentifier {
    if ([self respondsToSelector:@selector(applicationWithBundleIdentifier:)]) {
        return [self applicationWithBundleIdentifier:bundleIdentifier];
    } else if ([self respondsToSelector:@selector(applicationWithDisplayIdentifier:)]) {
        return [self applicationWithDisplayIdentifier:bundleIdentifier];
    }
    [ZYCompatibilitySystem showWarning:@"Unable to find valid -[SBApplicationController applicationWithBundleIdentifier:] replacement"];
    return nil;
}
%end

%hook SBToAppsWorkspaceTransaction
- (void)_willBegin {
    @autoreleasepool {
        NSArray *apps = nil;
        if ([self respondsToSelector:@selector(toApplications)]) {
            apps = [self toApplications];
        } else {
            apps = [MSHookIvar<NSArray*>(self, "_toApplications") copy];
        }
        for (SBApplication *app in apps) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ZYDesktopManager.sharedInstance removeAppWithIdentifier:app.bundleIdentifier animated:NO forceImmediateUnload:YES];
            });
        }
    }
    %orig;
}

// On iOS 8.3 and above, on the iPad, if a FBWindowContextWhatever creates a hosting context / enabled hosting, all the other hosted windows stop.
// This fixes that.
- (void)_didComplete {
    %orig;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [ZYHostedAppView iPad_iOS83_fixHosting];
    }
    // can't hurt to check all devices - especially if it changes/has changed to include phones.
    // actually it did hurt

}
%end

%hook SpringBoard
-(void)noteInterfaceOrientationChanged:(int)arg1 duration:(float)arg2 {
    %orig;
    [ZYSnapshotProvider.sharedInstance forceReloadEverything];
}
%end

%hook SBApplication
- (void)didActivateWithTransactionID:(unsigned long long)arg1 {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ZYSnapshotProvider.sharedInstance forceReloadOfSnapshotForIdentifier:self.bundleIdentifier];
    });

    %orig;
}
%end


%hook UIScreen
%new - (CGRect)ZY_interfaceOrientedBounds {
    if ([self respondsToSelector:@selector(_interfaceOrientedBounds)]) {
        return [self _interfaceOrientedBounds];
    }
    return [self bounds];
}
%end

void respring_notification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

void reset_settings_notification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [ZYSettings.sharedSettings resetSettings];
}

%ctor {
    IF_SPRINGBOARD {
        %init;
        LOAD_ASPHALEIA;

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, respring_notification, CFSTR("com.shade.zypen/Respring"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, reset_settings_notification, CFSTR("com.shade.zypen/ResetSettings"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}
