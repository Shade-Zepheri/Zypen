#import "headers.h"
#import "ZYSettings.h"
#import "ZYDesktopManager.h"
#import "ZYDesktopWindow.h"

BOOL launchNextOpenIntoWindow = NO;
BOOL override = NO;
BOOL allowOpenApp = NO;

%hook SBIconController
- (void)iconWasTapped:(__unsafe_unretained SBApplicationIcon*)arg1 {
	if ([ZYSettings.sharedSettings windowedMultitaskingEnabled] && [ZYSettings.sharedSettings launchIntoWindows] && arg1.application) {
		[ZYDesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:arg1.application animated:YES];
		override = YES;
	}
	%orig;
}

- (void)_launchIcon:(unsafe_id)icon {
	if (!override) {
    %orig;
  } else {
    override = NO;
  }
}
%end

%hook SBUIController
- (void)activateApplicationAnimated:(__unsafe_unretained SBApplication*)arg1 {
	// Broken
	//if (launchNextOpenIntoWindow)

	if ([ZYSettings.sharedSettings windowedMultitaskingEnabled] && [ZYSettings.sharedSettings launchIntoWindows] && !allowOpenApp) {
		[ZYDesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:arg1 animated:YES];
		//launchNextOpenIntoWindow = NO;
		return;
	} else {
		[ZYDesktopManager.sharedInstance removeAppWithIdentifier:arg1.bundleIdentifier animated:NO forceImmediateUnload:YES];
	}
	%orig;
}

- (void)activateApplication:(__unsafe_unretained SBApplication*)arg1 {
	// Broken
	//if (launchNextOpenIntoWindow)

	if ([ZYSettings.sharedSettings windowedMultitaskingEnabled] && [ZYSettings.sharedSettings launchIntoWindows] && !allowOpenApp) {
		[ZYDesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:arg1 animated:YES];
		//launchNextOpenIntoWindow = NO;
		return;
	} else {
		[ZYDesktopManager.sharedInstance removeAppWithIdentifier:arg1.bundleIdentifier animated:NO forceImmediateUnload:YES];
	}
	%orig;
}
%end
