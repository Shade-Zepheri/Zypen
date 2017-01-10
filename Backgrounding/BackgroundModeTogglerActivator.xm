#import <libactivator/libactivator.h>
#import "ZYBackgrounder.h"
#import "ZYSettings.h"

@interface ZYActivatorBackgrounderToggleModeListener : NSObject <LAListener, UIAlertViewDelegate>
@end

static ZYActivatorBackgrounderToggleModeListener *sharedInstance$ZYActivatorBackgrounderToggleModeListener;

@implementation ZYActivatorBackgrounderToggleModeListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    SBApplication *app = [UIApplication sharedApplication]._accessibilityFrontMostApplication;

    if (!app) {
      return;
    }
    NSString *friendlyCurrentBackgroundMode = FriendlyNameForBackgroundMode((ZYBackgroundMode)[ZYBackgrounder.sharedInstance backgroundModeForIdentifier:app.bundleIdentifier]);

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Zypen" message:[NSString stringWithFormat:@"Which backgrounding mode would you like to enable for %@ (currently %@)?",app.displayName,friendlyCurrentBackgroundMode] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Force Foreground", @"Native", @"Suspend Immediately", @"Disable", nil];

    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    SBApplication *app = UIApplication.sharedApplication._accessibilityFrontMostApplication;
    if (!app) {
      return;
    }
    BOOL dismissApp = [[%c(ZYSettings) sharedSettings] exitAppAfterUsingActivatorAction];

    if (buttonIndex == [alertView cancelButtonIndex]) {
        return;
    }
    if (buttonIndex == 1) {
        // Force foreground
        [ZYBackgrounder.sharedInstance temporarilyApplyBackgroundingMode:ZYBackgroundModeForcedForeground forApplication:app andCloseForegroundApp:dismissApp];
    } else if (buttonIndex == 2) {
        // Native
        [ZYBackgrounder.sharedInstance temporarilyApplyBackgroundingMode:ZYBackgroundModeNative forApplication:app andCloseForegroundApp:dismissApp];
    } else if (buttonIndex == 3) {
        [ZYBackgrounder.sharedInstance temporarilyApplyBackgroundingMode:ZYBackgroundModeSuspendImmediately forApplication:app andCloseForegroundApp:dismissApp];
    } else {
        [ZYBackgrounder.sharedInstance temporarilyApplyBackgroundingMode:ZYBackgroundModeForceNone forApplication:app andCloseForegroundApp:dismissApp];
    }
}
@end

%ctor {
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
        sharedInstance$ZYActivatorBackgrounderToggleModeListener = [[ZYActivatorBackgrounderToggleModeListener alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance$ZYActivatorBackgrounderToggleModeListener forName:@"com.shade.zypen.aura.togglemode"];
    }
}
